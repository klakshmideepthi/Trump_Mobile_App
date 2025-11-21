import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_manager.dart';
import '../services/firebase_order_manager.dart';

class UserRegistrationViewModel extends ChangeNotifier {
  final FirebaseManager _firebaseManager = FirebaseManager();
  final FirebaseOrderManager _orderManager = FirebaseOrderManager();

  // Account Information
  String accountType = '';
  String email = '';
  String password = '';
  String confirmPassword = '';

  // Contact Information
  String firstName = '';
  String lastName = '';
  String phoneNumber = '';

  // Shipping Address
  String street = '';
  String aptNumber = '';
  String zip = '';
  String city = '';
  String state = '';
  String country = 'USA';

  // Device Information
  String deviceBrand = '';
  String deviceModel = '';
  String imei = '';
  bool deviceIsCompatible = false;
  bool supportsESIM = true; // Default to true
  bool supportsPhysicalSIM = true; // Default to true

  // SIM & Number Selection
  String simType = ''; // "Physical" or "eSIM"
  String numberType = ''; // "New" or "Existing"
  String selectedPhoneNumber = '';

  // Port-In Information
  String portInAccountNumber = '';
  String portInPin = '';
  String portInCurrentCarrier = '';
  String portInAccountHolderName = '';
  bool portInSkipped = false;

  // eSIM Information
  bool isForThisDevice = true;
  bool showQRCode = false;

  // Billing Information
  String creditCardNumber = '';
  String billingDetails = '';
  String address = '';

  // Order Management
  String? userId;
  String? orderId;
  List<dynamic> previousOrders = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    userId = user.uid;
    email = user.email ?? '';

    // Update loading state on main thread
    SchedulerBinding.instance.addPostFrameCallback((_) {
      isLoading = true;
      notifyListeners();
    });

    try {
      // Load user registration data
      final userData = await _firebaseManager.getUserRegistration(user.uid);
      if (userData != null) {
        accountType = userData['accountType'] ?? '';
        // Update user registration data if needed (ensure userId is merged)
        await _firebaseManager.updateUserRegistration(user.uid, {
          'email': email,
          'accountType': accountType,
        });
      } else {
        // Create user registration if it doesn't exist
        await _firebaseManager.updateUserRegistration(user.uid, {
          'email': email,
          'accountType': accountType,
        });
      }

      // Load contact info
      final contactInfo = await _firebaseManager.getContactInfo(user.uid);
      if (contactInfo != null) {
        firstName = contactInfo['firstName'] ?? '';
        lastName = contactInfo['lastName'] ?? '';
        phoneNumber = contactInfo['phoneNumber'] ?? '';
      }

      // Load shipping address
      final shippingAddress = await _firebaseManager.getShippingAddress(user.uid);
      if (shippingAddress != null) {
        street = shippingAddress['street'] ?? '';
        aptNumber = shippingAddress['aptNumber'] ?? '';
        city = shippingAddress['city'] ?? '';
        state = shippingAddress['state'] ?? '';
        zip = shippingAddress['zip'] ?? '';
        country = shippingAddress['country'] ?? 'USA';
      }

      // Load previous orders using fetchCompletedOrders
      final orders = await _orderManager.fetchCompletedOrders(user.uid);
      previousOrders = orders;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      // Update loading state on main thread
      SchedulerBinding.instance.addPostFrameCallback((_) {
        isLoading = false;
        notifyListeners();
      });
    }
  }

  Future<bool> saveContactInfo() async {
    if (userId == null) return false;

    try {
      final contactData = {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'email': email,
      };

      final addressData = {
        'street': street,
        'aptNumber': aptNumber,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
      };

      // Save to user defaults first
      await _firebaseManager.saveContactInfo(userId!, contactData);
      await _firebaseManager.saveShippingAddress(userId!, addressData);

      // If order exists, save directly to order (updateUserDefault=false to avoid double save)
      if (orderId != null) {
        await _firebaseManager.saveOrderContactInfo(
          userId: userId!,
          orderId: orderId!,
          contactData: contactData,
          updateUserDefault: false, // Already saved above
        );
        await _firebaseManager.saveOrderShippingAddress(
          userId: userId!,
          orderId: orderId!,
          addressData: addressData,
          updateUserDefault: false, // Already saved above
        );
      }

      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveDeviceInfo() async {
    if (userId == null || orderId == null) return false;

    try {
      await _firebaseManager.updateOrder(userId!, orderId!, {
        'deviceBrand': deviceBrand,
        'deviceModel': deviceModel,
        'imei': imei,
        'deviceIsCompatible': deviceIsCompatible,
        'supportsESIM': supportsESIM,
        'supportsPhysicalSIM': supportsPhysicalSIM,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveSimSelection() async {
    if (userId == null || orderId == null) return false;

    try {
      await _firebaseManager.updateOrder(userId!, orderId!, {
        'simType': simType,
      });
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveNumberSelection() async {
    if (userId == null || orderId == null) return false;

    try {
      final data = {
        'numberType': numberType,
        'selectedPhoneNumber': selectedPhoneNumber,
        'portInSkipped': portInSkipped,
      };

      if (numberType == 'Existing') {
        data.addAll({
          'portInAccountNumber': portInAccountNumber,
          'portInPin': portInPin,
          'portInCurrentCarrier': portInCurrentCarrier,
          'portInAccountHolderName': portInAccountHolderName,
        });
      }

      if (simType == 'eSIM') {
        data.addAll({
          'isForThisDevice': isForThisDevice,
          'showQRCode': showQRCode,
        });
      }

      await _firebaseManager.updateOrder(userId!, orderId!, data);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveBillingInfo() async {
    if (userId == null || orderId == null) return false;

    try {
      final billingData = {
        'creditCardNumber': creditCardNumber,
        'billingDetails': billingDetails,
        'address': address,
        'country': country,
        'billingCompleted': true,
      };

      // Use saveBillingAddress to save billing info to order
      await _firebaseManager.saveBillingAddress(
        userId: userId!,
        orderId: orderId!,
        addressData: billingData,
      );
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeOrder() async {
    if (userId == null || orderId == null) return false;

    try {
      await _orderManager.markOrderCompleted(userId!, orderId!);
      resetOrderSpecificFields();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> prefillFromOrder(String orderId) async {
    if (userId == null) return;

    try {
      // Get order data
      final orderData = await _orderManager.fetchOrderDocument(userId!, orderId);
      if (orderData != null) {
        this.orderId = orderId;
        
        // Get contact info from order using dedicated method
        final contactInfo = await _firebaseManager.getOrderContactInfo(userId!, orderId);
        if (contactInfo != null) {
          firstName = contactInfo['firstName'] ?? '';
          lastName = contactInfo['lastName'] ?? '';
          phoneNumber = contactInfo['phoneNumber'] ?? '';
          email = contactInfo['email'] ?? email;
        }
        
        // Get shipping address from order using dedicated method
        final shippingAddress = await _firebaseManager.getOrderShippingAddress(userId!, orderId);
        if (shippingAddress != null) {
          street = shippingAddress['street'] ?? '';
          aptNumber = shippingAddress['aptNumber'] ?? '';
          city = shippingAddress['city'] ?? '';
          state = shippingAddress['state'] ?? '';
          zip = shippingAddress['zip'] ?? '';
        }
        
        // Get billing address from order using dedicated method
        final billingAddress = await _firebaseManager.getBillingAddress(userId!, orderId);
        if (billingAddress != null) {
          creditCardNumber = billingAddress['creditCardNumber'] ?? '';
          billingDetails = billingAddress['billingDetails'] ?? '';
          address = billingAddress['address'] ?? '';
          country = billingAddress['country'] ?? country;
        }
        
        // Get other order fields directly from order data
        deviceBrand = orderData['deviceBrand'] ?? '';
        deviceModel = orderData['deviceModel'] ?? '';
        imei = orderData['imei'] ?? '';
        deviceIsCompatible = orderData['deviceIsCompatible'] ?? false;
        supportsESIM = orderData['supportsESIM'] ?? true;
        supportsPhysicalSIM = orderData['supportsPhysicalSIM'] ?? true;
        simType = orderData['simType'] ?? '';
        numberType = orderData['numberType'] ?? '';
        selectedPhoneNumber = orderData['selectedPhoneNumber'] ?? '';
        portInAccountNumber = orderData['portInAccountNumber'] ?? '';
        portInPin = orderData['portInPin'] ?? '';
        portInCurrentCarrier = orderData['portInCurrentCarrier'] ?? '';
        portInAccountHolderName = orderData['portInAccountHolderName'] ?? '';
        portInSkipped = orderData['portInSkipped'] ?? false;
        
        notifyListeners();
      }
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  void resetOrderSpecificFields() {
    deviceBrand = '';
    deviceModel = '';
    imei = '';
    deviceIsCompatible = false;
    supportsESIM = true;
    supportsPhysicalSIM = true;
    simType = '';
    selectedPhoneNumber = '';
    portInAccountNumber = '';
    portInPin = '';
    portInCurrentCarrier = '';
    portInAccountHolderName = '';
    portInSkipped = false;
    creditCardNumber = '';
    billingDetails = '';
    address = '';
    orderId = null;
    notifyListeners();
  }

  void resetAllUserData() {
    accountType = '';
    email = '';
    password = '';
    confirmPassword = '';
    firstName = '';
    lastName = '';
    phoneNumber = '';
    street = '';
    aptNumber = '';
    zip = '';
    city = '';
    state = '';
    country = 'USA';
    resetOrderSpecificFields();
    previousOrders = [];
    userId = null;
    notifyListeners();
  }
}


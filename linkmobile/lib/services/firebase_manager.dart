import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseManager {
  static final FirebaseManager _instance = FirebaseManager._internal();
  factory FirebaseManager() => _instance;
  FirebaseManager._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // User Management
  Future<void> saveUserRegistration(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserRegistration(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  // Update user registration data
  Future<void> updateUserRegistration(
    String userId,
    Map<String, dynamic> data,
  ) async {
    print('📝 updateUserRegistration called for userId: $userId');
    print('📝 Data to update: $data');

    // Ensure userId is included in the data for Firestore security rules
    final dataWithUserId = <String, dynamic>{
      ...data,
      'userId': userId,
    };

    final userRef = _firestore.collection('users').doc(userId);

    // Check if document exists first
    final doc = await userRef.get();

    if (doc.exists) {
      print('📄 Document exists, updating it');
      // Document exists, update it
      await userRef.update(dataWithUserId);
      print('✅ Document updated successfully');
    } else {
      print('📄 Document doesn\'t exist, creating it');
      // Document doesn't exist, create it
      await userRef.set(dataWithUserId, SetOptions(merge: true));
      print('✅ Document created successfully');
    }
  }

  // Contact Info
  Future<void> saveContactInfo(String userId, Map<String, dynamic> contactData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('contactInfo')
        .doc('primary')
        .set(contactData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getContactInfo(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('contactInfo')
        .doc('primary')
        .get();
    return doc.data();
  }

  // Shipping Address
  Future<void> saveShippingAddress(String userId, Map<String, dynamic> addressData) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('shippingAddress')
        .doc('primary')
        .set(addressData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getShippingAddress(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shippingAddress')
        .doc('primary')
        .get();
    return doc.data();
  }

  // Order Management
  Future<String> createNewOrder({
    required String userId,
    required String planId,
    required String planName,
    required double planPrice,
    String? carrier,
    String? planCode,
  }) async {
    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc();

    final orderId = orderRef.id;

    // Match TrumpMobile Swift implementation exactly
    final orderData = {
      'orderId': orderId,
      'userId': userId,
      'status': 'pending',
      'currentStep': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'plan_id': int.tryParse(planId) ?? planId,
      'planName': planName,
      'planPrice': planPrice.toInt(),
      'amount': planPrice,
      // Additional fields as requested
      if (carrier != null && carrier.isNotEmpty) 'carrier': carrier,
      if (planCode != null && planCode.isNotEmpty) 'plan_code': int.tryParse(planCode) ?? planCode,
      'billingCompleted': false,
      'orderDate': FieldValue.serverTimestamp(),
    };

    await orderRef.set(orderData);
    print('✅ Order created with ID: $orderId');
    return orderId;
  }

  Future<void> updateOrder(String userId, String orderId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getOrder(String userId, String orderId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();
    return doc.data();
  }

  Future<void> deleteOrder(String userId, String orderId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .delete();
  }

  // Copy contact info to order
  Future<void> copyContactInfoToOrder(String userId, String orderId) async {
    final contactInfo = await getContactInfo(userId);
    if (contactInfo != null) {
      await updateOrder(userId, orderId, contactInfo);
    }
  }

  // Copy shipping address to order
  Future<void> copyShippingAddressToOrder(String userId, String orderId) async {
    final shippingAddress = await getShippingAddress(userId);
    if (shippingAddress != null) {
      await updateOrder(userId, orderId, shippingAddress);
    }
  }

  // Plan Caching
  /// Save plans to Firestore, keyed by zip code, enrollment type, and family plan status
  Future<void> savePlans({
    required String zipCode,
    required String enrollmentType,
    required String isFamilyPlan,
    required List<Map<String, dynamic>> plans,
  }) async {
    // Create a document ID based on zip code, enrollment type, and family plan status
    final documentId = '${zipCode}_${enrollmentType}_${isFamilyPlan}';
    
    // Save to Firestore
    final planData = {
      'zipCode': zipCode,
      'enrollmentType': enrollmentType,
      'isFamilyPlan': isFamilyPlan,
      'plans': plans,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    try {
      await _firestore.collection('plans').doc(documentId).set(planData);
      print('✅ Plans saved to Firestore for zip code: $zipCode');
    } catch (e) {
      print('❌ Error saving plans to Firestore: $e');
      rethrow;
    }
  }

  /// Retrieve plans from Firestore for a given zip code, enrollment type, and family plan status
  Future<List<Map<String, dynamic>>?> getPlans({
    required String zipCode,
    required String enrollmentType,
    required String isFamilyPlan,
  }) async {
    final documentId = '${zipCode}_${enrollmentType}_${isFamilyPlan}';
    
    try {
      final doc = await _firestore.collection('plans').doc(documentId).get();
      
      if (!doc.exists) {
        print('⚠️ No plans found in Firestore for zip code: $zipCode');
        return null;
      }
      
      final data = doc.data();
      if (data == null) {
        print('⚠️ No plans found in Firestore for zip code: $zipCode');
        return null;
      }
      
      final plansArray = data['plans'] as List<dynamic>?;
      if (plansArray == null || plansArray.isEmpty) {
        print('⚠️ No valid plans found in Firestore for zip code: $zipCode');
        return null;
      }
      
      // Convert to List<Map<String, dynamic>>
      final plans = plansArray
          .map((plan) => plan as Map<String, dynamic>)
          .toList();
      
      print('✅ Retrieved ${plans.length} plans from Firestore for zip code: $zipCode');
      return plans;
    } catch (e) {
      print('❌ Error getting plans from Firestore: $e');
      return null;
    }
  }

  // Save contact information directly to a specific order
  Future<void> saveOrderContactInfo({
    required String userId,
    required String orderId,
    required Map<String, dynamic> contactData,
    bool updateUserDefault = true,
  }) async {
    print('📞 saveOrderContactInfo called for orderId: $orderId');
    print('📞 contactData: $contactData');

    // Ensure userId is included in the data for Firestore security rules
    final dataWithUserId = <String, dynamic>{
      ...contactData,
      'userId': userId,
    };

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    // Save contact data directly to the order document
    await orderRef.set(dataWithUserId, SetOptions(merge: true));
    print('✅ Order contact info saved successfully');

    // If updateUserDefault is true, also update the user's default contact info
    if (updateUserDefault) {
      try {
        await saveContactInfo(userId, contactData);
        print('✅ Successfully synced order contact with user default');
      } catch (e) {
        print('⚠️ Updated order contact but failed to sync with user default: $e');
      }
    }
  }

  // Get contact information directly from a specific order
  Future<Map<String, dynamic>?> getOrderContactInfo(
    String userId,
    String orderId,
  ) async {
    print('📱 getOrderContactInfo called for orderId: $orderId');

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    final doc = await orderRef.get();

    if (!doc.exists) {
      print('⚠️ Order document does not exist');
      return null;
    }

    final data = doc.data();
    if (data == null) {
      print('⚠️ Order document exists but has no data');
      return null;
    }

    // Extract only contact-related fields
    final contactFields = ['firstName', 'lastName', 'phoneNumber', 'email'];
    final contactData = <String, dynamic>{};

    for (final field in contactFields) {
      if (data.containsKey(field)) {
        contactData[field] = data[field];
      }
    }

    print('✅ Successfully retrieved order contact info');
    return contactData.isEmpty ? null : contactData;
  }

  // Save shipping address directly to a specific order
  Future<void> saveOrderShippingAddress({
    required String userId,
    required String orderId,
    required Map<String, dynamic> addressData,
    bool updateUserDefault = true,
  }) async {
    print('📍 saveOrderShippingAddress called for orderId: $orderId');
    print('📍 addressData: $addressData');

    // Ensure userId is included in the data for Firestore security rules
    final dataWithUserId = <String, dynamic>{
      ...addressData,
      'userId': userId,
    };

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    // Save shipping address data directly to the order document
    await orderRef.set(dataWithUserId, SetOptions(merge: true));
    print('✅ Order shipping address saved successfully');

    // If updateUserDefault is true, also update the user's default shipping address
    if (updateUserDefault) {
      try {
        await saveShippingAddress(userId, addressData);
        print('✅ Successfully synced order shipping address with user default');
      } catch (e) {
        print('⚠️ Updated order shipping address but failed to sync with user default: $e');
      }
    }
  }

  // Get shipping address directly from a specific order
  Future<Map<String, dynamic>?> getOrderShippingAddress(
    String userId,
    String orderId,
  ) async {
    print('📱 getOrderShippingAddress called for orderId: $orderId');

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    final doc = await orderRef.get();

    if (!doc.exists) {
      print('⚠️ Order document does not exist');
      return null;
    }

    final data = doc.data();
    if (data == null) {
      print('⚠️ Order document exists but has no data');
      return null;
    }

    // Extract only shipping address-related fields
    final shippingFields = ['street', 'aptNumber', 'zip', 'city', 'state'];
    final shippingData = <String, dynamic>{};

    for (final field in shippingFields) {
      if (data.containsKey(field)) {
        shippingData[field] = data[field];
      }
    }

    print('✅ Successfully retrieved order shipping address');
    return shippingData.isEmpty ? null : shippingData;
  }

  // Save billing address directly to orders
  Future<void> saveBillingAddress({
    required String userId,
    required String orderId,
    required Map<String, dynamic> addressData,
  }) async {
    // Ensure userId is included in the data for Firestore security rules
    final dataWithUserId = <String, dynamic>{
      ...addressData,
      'userId': userId,
    };

    // Add billing info to the order document
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .set(dataWithUserId, SetOptions(merge: true));
  }

  // Get billing address from orders
  Future<Map<String, dynamic>?> getBillingAddress(
    String userId,
    String orderId,
  ) async {
    // Get billing info from the order document
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data();
    if (data == null) {
      return null;
    }

    // Extract only billing-related fields
    final billingFields = [
      'address',
      'country',
      'creditCardNumber',
      'billingDetails',
      'billingCity',
      'billingState',
    ];
    final billingData = <String, dynamic>{};

    for (final field in billingFields) {
      if (data.containsKey(field)) {
        billingData[field] = data[field];
      }
    }

    return billingData.isEmpty ? null : billingData;
  }

  // Save enrollment_id to order
  Future<void> saveEnrollmentId({
    required String userId,
    required String orderId,
    required String enrollmentId,
  }) async {
    print('💾 Saving enrollment_id: $enrollmentId to order: $orderId');

    final orderRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('orders')
        .doc(orderId);

    await orderRef.set({
      'enrollment_id': enrollmentId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    print('✅ Successfully saved enrollment_id to order');
  }

  /// Clear plans cache for a specific zip code (optional - for cleanup)
  Future<void> clearPlansCache({
    required String zipCode,
    required String enrollmentType,
    required String isFamilyPlan,
  }) async {
    final documentId = '${zipCode}_${enrollmentType}_${isFamilyPlan}';

    try {
      await _firestore.collection('plans').doc(documentId).delete();
      print('✅ Plans cache cleared for zip code: $zipCode');
    } catch (e) {
      print('❌ Error clearing plans cache: $e');
      rethrow;
    }
  }
}


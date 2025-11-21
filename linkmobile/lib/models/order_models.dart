import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

enum OrderStatus {
  pending,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Order {
  final String id;
  final String userId;
  final String planName;
  final double amount;
  final DateTime orderDate;
  final OrderStatus status;
  final bool billingCompleted;
  final String? phoneNumber;
  final String simType;
  final int? currentStep;

  Order({
    required this.id,
    required this.userId,
    required this.planName,
    required this.amount,
    required this.orderDate,
    required this.status,
    required this.billingCompleted,
    this.phoneNumber,
    required this.simType,
    this.currentStep,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      userId: map['userId'] ?? '',
      planName: map['planName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      orderDate: (map['orderDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'pending'),
        orElse: () => OrderStatus.pending,
      ),
      billingCompleted: map['billingCompleted'] ?? false,
      phoneNumber: map['phoneNumber'],
      simType: map['simType'] ?? '',
      currentStep: map['currentStep'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'planName': planName,
      'amount': amount,
      'orderDate': Timestamp.fromDate(orderDate),
      'status': status.name,
      'billingCompleted': billingCompleted,
      'phoneNumber': phoneNumber,
      'simType': simType,
      'currentStep': currentStep,
    };
  }
}

class OrderDetail {
  // Personal Information
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;

  // Address Information
  final String? street;
  final String? aptNumber;
  final String? city;
  final String? state;
  final String? zip;
  final String? country;

  // Device Information
  final String? deviceBrand;
  final String? deviceModel;
  final String? imei;
  final bool? deviceIsCompatible;

  // Service Information
  final String? numberType;
  final String? selectedPhoneNumber;
  final String? simType;
  final bool? portInSkipped;

  // Billing Information
  final String? creditCardNumber;
  final String? billingDetails;

  OrderDetail({
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.street,
    this.aptNumber,
    this.city,
    this.state,
    this.zip,
    this.country,
    this.deviceBrand,
    this.deviceModel,
    this.imei,
    this.deviceIsCompatible,
    this.numberType,
    this.selectedPhoneNumber,
    this.simType,
    this.portInSkipped,
    this.creditCardNumber,
    this.billingDetails,
  });

  factory OrderDetail.fromMap(Map<String, dynamic> map) {
    return OrderDetail(
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      street: map['street'],
      aptNumber: map['aptNumber'],
      city: map['city'],
      state: map['state'],
      zip: map['zip'],
      country: map['country'],
      deviceBrand: map['deviceBrand'],
      deviceModel: map['deviceModel'],
      imei: map['imei'],
      deviceIsCompatible: map['deviceIsCompatible'],
      numberType: map['numberType'],
      selectedPhoneNumber: map['selectedPhoneNumber'],
      simType: map['simType'],
      portInSkipped: map['portInSkipped'],
      creditCardNumber: map['creditCardNumber'],
      billingDetails: map['billingDetails'],
    );
  }
}


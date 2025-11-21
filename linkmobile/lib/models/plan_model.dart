class Plan {
  final int planId;
  final String planName;
  final int planPrice;
  final int totalPlanPrice;
  final String planDescription;
  final String? displayName;
  final String? displayDescription;
  final List<String> displayFeaturesDescription;
  final int data; // MB
  final int talk; // Minutes
  final int text; // Messages
  final String isUnlimitedPlan;
  final String isFamilyPlan;
  final String isPrepaidPostpaid;
  final int planExpiryDays;
  final String planExpiryType;
  final List<String> carrier;
  final List<String> planDiscountDetails;
  final String autopayDiscount;

  Plan({
    required this.planId,
    required this.planName,
    required this.planPrice,
    required this.totalPlanPrice,
    required this.planDescription,
    this.displayName,
    this.displayDescription,
    required this.displayFeaturesDescription,
    required this.data,
    required this.talk,
    required this.text,
    required this.isUnlimitedPlan,
    required this.isFamilyPlan,
    required this.isPrepaidPostpaid,
    required this.planExpiryDays,
    required this.planExpiryType,
    required this.carrier,
    required this.planDiscountDetails,
    required this.autopayDiscount,
  });

  factory Plan.fromJson(Map<String, dynamic> json) {
    // Helper function to convert string/number to int (matching Swift implementation)
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed?.round() ?? 0;
      }
      return 0;
    }

    return Plan(
      planId: parseInt(json['plan_id']),
      planName: json['plan_name'] as String? ?? '',
      planPrice: parseInt(json['plan_price']),
      totalPlanPrice: parseInt(json['total_plan_price']),
      planDescription: json['plan_description'] as String? ?? '',
      displayName: json['display_name'] as String?,
      displayDescription: json['display_description'] as String?,
      displayFeaturesDescription: 
          (json['display_features_description'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      data: parseInt(json['data']),
      talk: parseInt(json['talk']),
      text: parseInt(json['text']),
      isUnlimitedPlan: json['is_unlimited_plan'] as String? ?? 'N',
      isFamilyPlan: json['is_familyplan'] as String? ?? 'N',
      isPrepaidPostpaid: json['is_prepaid_postpaid'] as String? ?? 'prepaid',
      planExpiryDays: parseInt(json['plan_expiry_days'] ?? 0),
      planExpiryType: json['plan_expiry_type'] as String? ?? 'days',
      carrier: (json['carrier'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      planDiscountDetails: (json['plan_discount_details'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [],
      autopayDiscount: json['autopay_discount'] as String? ?? '0',
    );
  }
}

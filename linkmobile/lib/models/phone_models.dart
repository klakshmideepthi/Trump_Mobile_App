enum PhoneBrand {
  apple('Apple'),
  samsung('Samsung'),
  google('Google'),
  oneplus('OnePlus');

  final String displayName;
  const PhoneBrand(this.displayName);
}

class PhoneModel {
  final String id;
  final String name;
  final PhoneBrand brand;

  PhoneModel({
    required this.id,
    required this.name,
    required this.brand,
  });
}

class PhoneCatalog {
  static final PhoneCatalog _instance = PhoneCatalog._internal();
  factory PhoneCatalog() => _instance;
  PhoneCatalog._internal();

  final List<PhoneModel> allModels = [
    // Apple models - iPhone 16 series
    PhoneModel(id: '1', name: 'iPhone 16 Pro Max', brand: PhoneBrand.apple),
    PhoneModel(id: '2', name: 'iPhone 16 Pro', brand: PhoneBrand.apple),
    PhoneModel(id: '3', name: 'iPhone 16 Plus', brand: PhoneBrand.apple),
    PhoneModel(id: '4', name: 'iPhone 16', brand: PhoneBrand.apple),
    // iPhone 15 series
    PhoneModel(id: '5', name: 'iPhone 15 Pro Max', brand: PhoneBrand.apple),
    PhoneModel(id: '6', name: 'iPhone 15 Pro', brand: PhoneBrand.apple),
    PhoneModel(id: '7', name: 'iPhone 15 Plus', brand: PhoneBrand.apple),
    PhoneModel(id: '8', name: 'iPhone 15', brand: PhoneBrand.apple),
    // iPhone 14 series
    PhoneModel(id: '9', name: 'iPhone 14 Pro Max', brand: PhoneBrand.apple),
    PhoneModel(id: '10', name: 'iPhone 14 Pro', brand: PhoneBrand.apple),
    PhoneModel(id: '11', name: 'iPhone 14 Plus', brand: PhoneBrand.apple),
    PhoneModel(id: '12', name: 'iPhone 14', brand: PhoneBrand.apple),
    // iPhone 13 series
    PhoneModel(id: '13', name: 'iPhone 13 Pro Max', brand: PhoneBrand.apple),
    PhoneModel(id: '14', name: 'iPhone 13 Pro', brand: PhoneBrand.apple),
    PhoneModel(id: '15', name: 'iPhone 13', brand: PhoneBrand.apple),
    PhoneModel(id: '16', name: 'iPhone 13 mini', brand: PhoneBrand.apple),
    // iPhone 12 series
    PhoneModel(id: '17', name: 'iPhone 12 Pro Max', brand: PhoneBrand.apple),
    PhoneModel(id: '18', name: 'iPhone 12 Pro', brand: PhoneBrand.apple),
    PhoneModel(id: '19', name: 'iPhone 12', brand: PhoneBrand.apple),
    PhoneModel(id: '20', name: 'iPhone 12 mini', brand: PhoneBrand.apple),
    
    // Samsung models
    PhoneModel(id: '21', name: 'Galaxy S24 Ultra', brand: PhoneBrand.samsung),
    PhoneModel(id: '22', name: 'Galaxy S24+', brand: PhoneBrand.samsung),
    PhoneModel(id: '23', name: 'Galaxy S24', brand: PhoneBrand.samsung),
    PhoneModel(id: '24', name: 'Galaxy S23 Ultra', brand: PhoneBrand.samsung),
    PhoneModel(id: '25', name: 'Galaxy S23+', brand: PhoneBrand.samsung),
    PhoneModel(id: '26', name: 'Galaxy S23', brand: PhoneBrand.samsung),
    PhoneModel(id: '27', name: 'Galaxy Note 20 Ultra', brand: PhoneBrand.samsung),
    
    // Google models
    PhoneModel(id: '28', name: 'Pixel 8 Pro', brand: PhoneBrand.google),
    PhoneModel(id: '29', name: 'Pixel 8', brand: PhoneBrand.google),
    PhoneModel(id: '30', name: 'Pixel 7 Pro', brand: PhoneBrand.google),
    PhoneModel(id: '31', name: 'Pixel 7', brand: PhoneBrand.google),
    
    // OnePlus models
    PhoneModel(id: '32', name: 'OnePlus 12', brand: PhoneBrand.oneplus),
    PhoneModel(id: '33', name: 'OnePlus 11', brand: PhoneBrand.oneplus),
    PhoneModel(id: '34', name: 'OnePlus 10 Pro', brand: PhoneBrand.oneplus),
  ];

  List<PhoneModel> modelsForBrand(PhoneBrand brand) {
    return allModels.where((model) => model.brand == brand).toList();
  }

  /// Maps iOS model identifier (from utsname.machine) to iPhone model name
  /// Returns null if identifier is not recognized
  static String? getiPhoneModelFromIdentifier(String identifier) {
    print('getiPhoneModelFromIdentifier called with: "$identifier"');
    
    // iPhone 16 series
    switch (identifier) {
      case 'iPhone17,1':
        print('Matched iPhone17,1 -> iPhone 16 Pro');
        return 'iPhone 16 Pro';
      case 'iPhone17,2':
        print('Matched iPhone17,2 -> iPhone 16 Pro Max');
        return 'iPhone 16 Pro Max';
      case 'iPhone17,3':
        print('Matched iPhone17,3 -> iPhone 16');
        return 'iPhone 16';
      case 'iPhone17,4':
        print('Matched iPhone17,4 -> iPhone 16 Plus');
        return 'iPhone 16 Plus';
    }

    // iPhone 15 series
    switch (identifier) {
      case 'iPhone16,1':
        print('Matched iPhone16,1 -> iPhone 15 Pro');
        return 'iPhone 15 Pro';
      case 'iPhone16,2':
        print('Matched iPhone16,2 -> iPhone 15 Pro Max');
        return 'iPhone 15 Pro Max';
      case 'iPhone15,4':
        print('Matched iPhone15,4 -> iPhone 15');
        return 'iPhone 15';
      case 'iPhone15,5':
        print('Matched iPhone15,5 -> iPhone 15 Plus');
        return 'iPhone 15 Plus';
    }

    // iPhone 14 series
    switch (identifier) {
      case 'iPhone15,2':
        print('Matched iPhone15,2 -> iPhone 14 Pro');
        return 'iPhone 14 Pro';
      case 'iPhone15,3':
        print('Matched iPhone15,3 -> iPhone 14 Pro Max');
        return 'iPhone 14 Pro Max';
      case 'iPhone14,7':
        print('Matched iPhone14,7 -> iPhone 14');
        return 'iPhone 14';
      case 'iPhone14,8':
        print('Matched iPhone14,8 -> iPhone 14 Plus');
        return 'iPhone 14 Plus';
    }

    // iPhone 13 series
    switch (identifier) {
      case 'iPhone14,2':
        print('Matched iPhone14,2 -> iPhone 13 Pro');
        return 'iPhone 13 Pro';
      case 'iPhone14,3':
        print('Matched iPhone14,3 -> iPhone 13 Pro Max');
        return 'iPhone 13 Pro Max';
      case 'iPhone14,4':
        print('Matched iPhone14,4 -> iPhone 13 mini');
        return 'iPhone 13 mini';
      case 'iPhone14,5':
        print('Matched iPhone14,5 -> iPhone 13');
        return 'iPhone 13';
    }

    // iPhone 12 series
    switch (identifier) {
      case 'iPhone13,1':
        print('Matched iPhone13,1 -> iPhone 12 mini');
        return 'iPhone 12 mini';
      case 'iPhone13,2':
        print('Matched iPhone13,2 -> iPhone 12');
        return 'iPhone 12';
      case 'iPhone13,3':
        print('Matched iPhone13,3 -> iPhone 12 Pro');
        return 'iPhone 12 Pro';
      case 'iPhone13,4':
        print('Matched iPhone13,4 -> iPhone 12 Pro Max');
        return 'iPhone 12 Pro Max';
    }
    
    print('WARNING: Identifier "$identifier" does not match any known iPhone pattern');
    return null;
  }

  /// Get SIM compatibility for a phone model (U.S. market)
  /// Returns a map with 'supportsESIM' and 'supportsPhysicalSIM' boolean values
  static Map<String, bool> getSimCompatibilityForModel(String modelName) {
    final modelNameLower = modelName.toLowerCase();
    
    // iPhone 16 series (U.S. models are eSIM-only)
    if (modelNameLower.contains('iphone 16')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': false};
    }
    
    // iPhone 15 series (U.S. models are eSIM-only)
    if (modelNameLower.contains('iphone 15')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': false};
    }
    
    // iPhone 14 series (U.S. models are eSIM-only)
    if (modelNameLower.contains('iphone 14')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': false};
    }
    
    // iPhone 13 and earlier - support both (U.S. models have physical SIM + eSIM)
    if (modelNameLower.contains('iphone 13') || 
        modelNameLower.contains('iphone 12')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Samsung Galaxy S24 series - support both
    if (modelNameLower.contains('galaxy s24')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Samsung Galaxy S23 series - support both (likely)
    if (modelNameLower.contains('galaxy s23')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Samsung Galaxy Note series - support both (likely)
    if (modelNameLower.contains('galaxy note')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Google Pixel 8 series - support both
    if (modelNameLower.contains('pixel 8')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Google Pixel 7 series - support both (likely)
    if (modelNameLower.contains('pixel 7')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // OnePlus 12 - support both
    if (modelNameLower.contains('oneplus 12')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // OnePlus 11 and earlier - support both (likely)
    if (modelNameLower.contains('oneplus 11') ||
        modelNameLower.contains('oneplus 10')) {
      return {'supportsESIM': true, 'supportsPhysicalSIM': true};
    }
    
    // Default: assume both are supported if model is in catalog
    // This handles any models not explicitly listed above
    return {'supportsESIM': true, 'supportsPhysicalSIM': true};
  }
}


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

  // Mapping from Android model codes to marketing names
  static final Map<String, String> _modelCodeToMarketingName = {
    // Google Pixel devices
    'G4QUR': 'Pixel 10 Pro',
    'GLBW0': 'Pixel 10',
    'GUL82': 'Pixel 10 Pro XL',
    'G1KAW': 'Pixel', // TBD
    'GWSQ2': 'Pixel', // TBD
    'GXQ96': 'Pixel 9a',
    'GGH2X': 'Pixel 9 Pro Fold',
    'GC15S': 'Pixel 9 Pro Fold',
    'GRY0E': 'Pixel Watch 3 Large',
    'GBDU9': 'Pixel Watch 3',
    'GR83Y': 'Pixel 9 Pro',
    'GWVK6': 'Pixel 9 Pro',
    'GEC77': 'Pixel 9 Pro',
    'G2YBB': 'Pixel 9',
    'GUR25': 'Pixel 9',
    'G1B60': 'Pixel 9',
    'GGX8B': 'Pixel 9 Pro XL',
    'GQ57S': 'Pixel 9 Pro XL',
    'GZC4K': 'Pixel 9 Pro XL',
    'GKV4X': 'Pixel 8a',
    'G1MNW': 'Pixel 8 Pro',
    'GKWS6': 'Pixel 8',
    'G9BQD': 'Pixel 8',
    'GPJ41': 'Pixel 8',
    'GE2AE': 'Pixel 7 Pro',
    'GQML3': 'Pixel 7',
    'GWKK3': 'Pixel 7a',
    'G8V0U': 'Pixel 6 Pro',
    'G9S9B': 'Pixel 6',
    'GX7AS': 'Pixel 6a',
    'G9FPL': 'Pixel Fold',
    'GD2WG': 'Pixel Watch 2',
    'GWT9R': 'Pixel Watch',
    
    // Samsung devices
    'SM-F766U1': 'Galaxy Z Flip7 SE',
    'SM-F966U1': 'Galaxy Z Fold7 SE',
    'SM-F766U': 'Galaxy Z Flip7',
    'SM-F966U': 'Galaxy Z Fold7',
    'SM-S937U': 'Galaxy S25 Edge',
    'SM-S931U': 'Galaxy S25',
    'SM-S936U': 'Galaxy S25+',
    'SM-S938U': 'Galaxy S25 Ultra',
    'SM-S931U1': 'Galaxy S25 SE',
    'SM-S936U1': 'Galaxy S25 Plus SE',
    'SM-S938U1': 'Galaxy S25 Ultra SE',
    'SM-A266U1': 'Galaxy A26 5G SE',
    'SM-A366U1': 'Galaxy A36 5G SE',
    'SM-A366U': 'Galaxy A36 5G',
    'SM-A566U1': 'A56 5G',
    'SM-A166U1': 'Galaxy A16 SE',
    'SM-A256U1': 'Galaxy A25',
    'SM-A156U': 'Galaxy A16 5G',
    'SM-A156U1': 'Galaxy A15 5G',
    'SM-S721U1': 'Galaxy S24 FE SE',
    'SM-S721U': 'Galaxy S24 FE',
    'SM-S921U': 'Galaxy S24',
    'SM-S921U1': 'Galaxy S24 SE',
    'SM-S926U': 'Galaxy S24+',
    'SM-S926U1': 'Galaxy S24 Plus SE',
    'SM-S928U': 'Galaxy S24 Ultra',
    'SM-S928U1': 'Galaxy S24 Ultra SE',
    'SM-S911U': 'Galaxy S23',
    'SM-S911U1': 'Galaxy S23 SE',
    'SM-S916U': 'Galaxy S23+',
    'SM-S916U1': 'Galaxy S23 + SE',
    'SM-S918U': 'Galaxy S23 Ultra',
    'SM-S918U1': 'Galaxy S23 Ultra SE',
    'SM-S711U': 'Galaxy S23 FE',
    'SM-S711U1': 'Galaxy S23 FE SE',
    'SM-S901U': 'Galaxy S22',
    'SM-S901U1': 'Galaxy S22 SE',
    'SM-S906U': 'Galaxy S22+',
    'SM-S906U1': 'Galaxy S22+',
    'SM-S908U': 'Galaxy S22 Ultra',
    'SM-S908U1': 'Galaxy S22 Ultra SE',
    'SM-F741U': 'Galaxy Z Flip6',
    'SM-F741U1': 'Flip 6 Unlocked',
    'SM-F956U': 'Galaxy Z Fold6',
    'SM-F956U1': 'Fold 6 Unlocked',
    'SM-F731U': 'Galaxy Z Flip5',
    'SM-F731U1': 'Galaxy Z Flip 5',
    'SM-F946U': 'Galaxy Z Fold5',
    'SM-F946U1': 'Galaxy Z Fold 5',
    'SM-F721U': 'Galaxy Z Flip4',
    'SM-F721U1': 'Galaxy Z Flip 4',
    'SM-F936U': 'Galaxy Z Fold4',
    'SM-F936U1': 'Galaxy Z Fold 4',
    'SM-F711U': 'Galaxy Z Flip3',
    'SM-F711U1': 'Galaxy Z Flip 3',
    'SM-F926U': 'Galaxy Z Fold3',
    'SM-F926U1': 'Galaxy Z Fold 3',
    'SM-A356U': 'Galaxy A35 5G',
    'SM-A356U1': 'A35 Unlocked',
    'SM-A546U': 'Galaxy A54 5G',
    'SM-A546U1': 'A54 5G Unlock',
    'SM-A135U': 'Galaxy A13',
    'SM-A135U1': 'Galaxy A13 LTE SE',
    'SM-A136U': 'Galaxy A13 5G',
    'SM-A136U1': 'Galaxy A13 5G SE',
    'SM-A146U': 'Galaxy A14 5G',
    'SM-A146U1': 'A14 5G SE',
    'SM-A156U': 'Galaxy A15 5G',
    'SM-A156U1': 'Galaxy A15 5G',
    'SM-A236U': 'Galaxy A23 5G',
    'SM-A326U': 'Galaxy A32 5G',
    'SM-A515U': 'Galaxy A51',
    'SM-A516U': 'Galaxy A51 5G',
    'SM-A526U': 'Galaxy A52 5G',
    'SM-A536U': 'Galaxy A53 5G',
    'SM-A536U1': 'Galaxy A53 5G SE',
    'SM-A716U': 'Galaxy A71 5G',
    'SM-G766U': 'Galaxy XCover7 Pro',
    'SM-G766U1': 'X Cover Pro 7',
    'SM-G736U': 'XCover6 Pro',
    'SM-G715A': 'Galaxy XCover Pro',
    'SM-G990U': 'Galaxy S21 FE',
    'SM-G990U1': 'GS21 FE SE',
    'SM-G990U2': 'Galaxy S21 FE',
    'SM-G990U3': 'GS21 FE SE',
    'SM-G991U': 'Galaxy S21',
    'SM-G991U1': 'S21 SE',
    'SM-G996U': 'Galaxy S21+',
    'SM-G996U1': 'S21 Plus SE',
    'SM-G998U': 'Galaxy S21 Ultra',
    'SM-G998U1': 'S21 Ultra SE',
    'SM-G981U': 'Galaxy S20',
    'SM-G981U1': 'S20 SE',
    'SM-G986U': 'Galaxy S20+',
    'SM-G986U1': 'S20 Plus SE',
    'SM-G988U': 'Galaxy S20 Ultra',
    'SM-G988U1': 'S20 Ultra SE',
    'SM-G781U': 'Galaxy S20 FE',
    'SM-G781U1': 'GS20 FE',
    'SM-N981U': 'Galaxy Note 20',
    'SM-N981U1': 'Note 20 SE',
    'SM-N986U': 'Galaxy Note 20 Ultra',
    'SM-N986U1': 'Note 20 Ultra SE',
    'SM-F707U': 'Galaxy Z Flip 5G',
    'SM-F700U': 'Galaxy Z Flip',
    'SM-F916U': 'Galaxy Z Fold 2 5G',
    'SM-X528U': 'Galaxy Tab S10 FE 5G',
    'SM-X828U': 'Galaxy Tab S10+ 5G',
    'SM-X518U': 'Galaxy Tab S9 FE 5G',
    'SM-X818U': 'Galaxy Tab S9+',
    'SM-X808U': 'Tab S8+ 5G',
    'SM-T738U': 'Galaxy Tab S7 FE 5G',
    'SM-T878U': 'Galaxy Tab S7',
    'SM-X218U': 'Galaxy Tab A9+ 5G',
    'SM-T227U': 'Galaxy Tab A7 Lite Kids Edition',
    'SM-L325U': 'Galaxy Watch8',
    'SM-L335U': 'Galaxy Watch8',
    'SM-L505U': 'Galaxy Watch8 Classic',
    'SM-L305U': 'Samsung Galaxy Watch7 40mm',
    'SM-L315U': 'Samsung Galaxy Watch7 44mm',
    'SM-L705U': 'Samsung Galaxy Watch Ultra',
    'SM-R866U': 'Galaxy Watch FE',
    
    // Motorola devices
    'XT2515-3': 'moto g power - 2025',
    'XT2513-3': 'moto g - 2025',
    'XT2517-2': 'moto g stylus -2025',
    'XT2551-2': 'motorola razr ultra 2025',
    'XT2519-1': 'motorola edge 2025',
    'XT2557-3': 'motorola razr+ 2025',
    'XT2553-3': 'moto razr 2025',
    'XT2517-1': 'moto g Stylus 5G - 2024',
    'XT2451-2': 'motorola razr+ 2024',
    'XT2451-1': 'motorola razr+ 2024',
    'XT2453-3': 'moto razr 2024',
    'XT2305-1': 'motorola edge 2023',
    'XT2419-2': 'moto g Stylus 5G - 2024',
    'XT2419-1': 'moto g Stylus 5G - 2024',
    'XT2415-3': 'moto g power 5G',
    'XT2415-1': 'moto g power 5G',
    'XT2417-4': 'motog5g 2024',
    'XT2417-1': 'moto 5g 2024',
    'XT2315-4': 'moto g stylus 5G - 2023',
    'XT2215-2': 'moto g stylus 5G (2022)',
    'XT2313-3': 'moto g 5G',
    'XT2321-5': 'motorola razr+ 2023',
    'XT2323-5': 'motorola razr',
    'XT2205-2': 'motorola edge - 2022',
    'XT2413-3': 'moto g play - 2024',
    'XT2413-2': 'Moto g play - 2024',
    'XT2413-1': 'moto G 2025',
    'XT2515-1': 'Moto G Power 2025',
    'XT2405-1': 'Moto EDGE (TBC)',
    
    // OnePlus devices
    'CPH2647': 'OnePlus 13R',
    'CPH2655': 'OnePlus 13',
    'CPH2611': 'OnePlus 12R',
    'CPH2583': 'OnePlus 12',
    'CPH2551': 'OnePlus Open',
    
    // Sonim devices
    'X320': 'Sonim XP3plus 5G',
    'X800': 'XP Pro',
    
    // Other devices
    'A65L': 'A65L',
    'A671': 'A671',
    'A551': 'A551',
    'TA-1658': 'HMD FUSION',
    'TA-1600': 'HMD SKYLINE',
    'TA-1590': 'HMD Vibe',
    'TA-1584': 'Nokia C210',
  };

  // Device compatibility data based on SIM Type from the provided document
  static final Map<String, Map<String, bool>> _deviceCompatibilityMap = {
    // Google Pixel devices - DSDS (4FF/eSIM) = both
    'Pixel 10 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 10': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 10 Pro XL': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 9 Pro Fold': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 9 Pro XL': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 9 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 9': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 9a': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 8 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 8': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 8a': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 7 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 7': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 7a': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 6 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 6': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel 6a': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Pixel Fold': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    
    // Samsung devices - DSDS (4FF/eSIM) = both, eSIM/4FF = both, 4FF = physical only, eUICC = eSIM only
    'Galaxy Z Flip7 SE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold7 SE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip7': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold7': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S25 Edge': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S25': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S25+': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S25 Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S24 FE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S24': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S24+': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S24 Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S23': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S23+': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S23 Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S23 FE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S22': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S22+': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S22 Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip6': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold6': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip5': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold5': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip4': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold4': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip3': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Z Fold3': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A36 5G': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A35 5G': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A54 5G': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A26 5G SE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A25': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy A16 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A15 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A14 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A13 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A13': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A23 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A32 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A51': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A51 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A52 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A53 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy A71 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy XCover7 Pro': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'X Cover Pro 7': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'XCover6 Pro': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy XCover Pro': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy Note 20': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy Note 20 Ultra': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy S21': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy S21+': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy S21 Ultra': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy S21 FE': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'Galaxy S20': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy S20+': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy S20 Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy S20 FE': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy Z Flip': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy Z Fold 2 5G': {'supportsESIM': false, 'supportsPhysicalSIM': true},
    'Galaxy Watch8': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy Watch8 Classic': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Samsung Galaxy Watch7 40mm': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Samsung Galaxy Watch7 44mm': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Samsung Galaxy Watch Ultra': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    'Galaxy Watch FE': {'supportsESIM': true, 'supportsPhysicalSIM': false},
    
    // OnePlus devices - DSDS (4FF/eSIM) = both
    'OnePlus 13R': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'OnePlus 13': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'OnePlus 12R': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'OnePlus 12': {'supportsESIM': true, 'supportsPhysicalSIM': true},
    'OnePlus Open': {'supportsESIM': true, 'supportsPhysicalSIM': true},
  };

  /// Maps Android model code to marketing name
  /// Returns the marketing name if found, otherwise returns null
  static String? getMarketingNameFromModelCode(String modelCode) {
    // Try exact match first
    if (_modelCodeToMarketingName.containsKey(modelCode)) {
      return _modelCodeToMarketingName[modelCode];
    }
    
    // Try case-insensitive match
    final modelCodeUpper = modelCode.toUpperCase();
    for (var entry in _modelCodeToMarketingName.entries) {
      if (entry.key.toUpperCase() == modelCodeUpper) {
        return entry.value;
      }
    }
    
    // Try partial match (model code contains key or vice versa)
    for (var entry in _modelCodeToMarketingName.entries) {
      final keyUpper = entry.key.toUpperCase();
      if (modelCodeUpper.contains(keyUpper) || keyUpper.contains(modelCodeUpper)) {
        return entry.value;
      }
    }
    
    return null;
  }

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
    
    // First, try exact match in compatibility map
    if (_deviceCompatibilityMap.containsKey(modelName)) {
      return _deviceCompatibilityMap[modelName]!;
    }
    
    // Try case-insensitive match
    for (var entry in _deviceCompatibilityMap.entries) {
      if (entry.key.toLowerCase() == modelNameLower) {
        return entry.value;
      }
    }
    
    // Try partial match (contains)
    for (var entry in _deviceCompatibilityMap.entries) {
      final keyLower = entry.key.toLowerCase();
      if (modelNameLower.contains(keyLower) || keyLower.contains(modelNameLower)) {
        return entry.value;
      }
    }
    
    // Fallback to iPhone-specific logic
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
    
    // Default: assume both are supported if model is in catalog
    // This handles any models not explicitly listed above
    return {'supportsESIM': true, 'supportsPhysicalSIM': true};
  }
}


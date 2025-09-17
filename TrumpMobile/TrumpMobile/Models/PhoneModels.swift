import Foundation

// Define phone brands
enum PhoneBrand: String, CaseIterable, Identifiable {
  case apple = "Apple"
  case samsung = "Samsung"
  case google = "Google"
  case oneplus = "OnePlus"

  var id: String { self.rawValue }
}

// Define phone models by brand
struct PhoneModel: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let brand: PhoneBrand
}

// Phone catalog
class PhoneCatalog {
  static let shared = PhoneCatalog()

  let allModels: [PhoneModel] = [
    // Apple models
    PhoneModel(name: "iPhone 15 Pro Max", brand: .apple),
    PhoneModel(name: "iPhone 15 Pro", brand: .apple),
    PhoneModel(name: "iPhone 15 Plus", brand: .apple),
    PhoneModel(name: "iPhone 15", brand: .apple),
    PhoneModel(name: "iPhone 14", brand: .apple),
    PhoneModel(name: "iPhone 13", brand: .apple),
    PhoneModel(name: "iPhone SE", brand: .apple),

    // Samsung models
    PhoneModel(name: "Galaxy S24 Ultra", brand: .samsung),
    PhoneModel(name: "Galaxy S24+", brand: .samsung),
    PhoneModel(name: "Galaxy S24", brand: .samsung),
    PhoneModel(name: "Galaxy S23", brand: .samsung),
    PhoneModel(name: "Galaxy Z Fold5", brand: .samsung),
    PhoneModel(name: "Galaxy Z Flip5", brand: .samsung),
    PhoneModel(name: "Galaxy A54", brand: .samsung),

    // Google models
    PhoneModel(name: "Pixel 8 Pro", brand: .google),
    PhoneModel(name: "Pixel 8", brand: .google),
    PhoneModel(name: "Pixel 7a", brand: .google),
    PhoneModel(name: "Pixel 7", brand: .google),
    PhoneModel(name: "Pixel Fold", brand: .google),

    // OnePlus models
    PhoneModel(name: "OnePlus 12", brand: .oneplus),
    PhoneModel(name: "OnePlus 11", brand: .oneplus),
    PhoneModel(name: "OnePlus 10 Pro", brand: .oneplus),
    PhoneModel(name: "OnePlus Nord", brand: .oneplus),
  ]

  // Get models filtered by brand
  func models(for brand: PhoneBrand) -> [PhoneModel] {
    return allModels.filter { $0.brand == brand }
  }
}

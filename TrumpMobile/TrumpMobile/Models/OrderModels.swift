import Firebase
import FirebaseFirestore
import Foundation

struct TrumpOrder: Identifiable, Codable {
  let id: String
  let userId: String
  let planName: String
  let amount: Double
  let orderDate: Date
  let status: OrderStatus
  let billingCompleted: Bool
  let phoneNumber: String?
  let simType: String
  let currentStep: Int?

  enum OrderStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case completed = "completed"
    case cancelled = "cancelled"

    var displayName: String {
      switch self {
      case .pending:
        return "Pending"
      case .completed:
        return "Completed"
      case .cancelled:
        return "Cancelled"
      }
    }
  }
}

struct OrderDetail {
  let orderId: String
  let userId: String
  let status: String
  let orderCompleted: Bool
  let createdAt: Date
  let updatedAt: Date
  let orderCompletionDate: Date?

  // Personal Information
  let firstName: String
  let lastName: String
  let email: String
  let phoneNumber: String

  // Address Information
  let street: String
  let aptNumber: String
  let city: String
  let state: String
  let zip: String
  let country: String

  // Device Information
  let deviceBrand: String
  let deviceModel: String
  let deviceIsCompatible: Bool
  let isForThisDevice: Bool
  let imei: String

  // Service Information
  let numberType: String
  let selectedPhoneNumber: String
  let simType: String
  let portInSkipped: Bool
  let showQRCode: Bool

  // Billing Information
  let billingDetails: String
  let creditCardNumber: String

  init(from data: [String: Any]) {
    self.orderId = data["orderId"] as? String ?? ""
    self.userId = data["userId"] as? String ?? ""
    self.status = data["status"] as? String ?? ""
    self.orderCompleted = data["orderCompleted"] as? Bool ?? false

    // Handle timestamps
    if let createdTimestamp = data["createdAt"] as? Timestamp {
      self.createdAt = createdTimestamp.dateValue()
    } else {
      self.createdAt = Date()
    }

    if let updatedTimestamp = data["updatedAt"] as? Timestamp {
      self.updatedAt = updatedTimestamp.dateValue()
    } else {
      self.updatedAt = Date()
    }

    if let completionTimestamp = data["orderCompletionDate"] as? Timestamp {
      self.orderCompletionDate = completionTimestamp.dateValue()
    } else {
      self.orderCompletionDate = nil
    }

    // Personal Information
    self.firstName = data["firstName"] as? String ?? ""
    self.lastName = data["lastName"] as? String ?? ""
    self.email = data["email"] as? String ?? ""
    self.phoneNumber = data["phoneNumber"] as? String ?? ""

    // Address Information
    self.street = data["street"] as? String ?? ""
    self.aptNumber = data["aptNumber"] as? String ?? ""
    self.city = data["city"] as? String ?? ""
    self.state = data["state"] as? String ?? ""
    self.zip = data["zip"] as? String ?? ""
    self.country = data["country"] as? String ?? ""

    // Device Information
    self.deviceBrand = data["deviceBrand"] as? String ?? ""
    self.deviceModel = data["deviceModel"] as? String ?? ""
    self.deviceIsCompatible = data["deviceIsCompatible"] as? Bool ?? false
    self.isForThisDevice = data["isForThisDevice"] as? Bool ?? false
    self.imei = data["imei"] as? String ?? ""

    // Service Information
    self.numberType = data["numberType"] as? String ?? ""
    self.selectedPhoneNumber = data["selectedPhoneNumber"] as? String ?? ""
    self.simType = data["simType"] as? String ?? ""
    self.portInSkipped = data["portInSkipped"] as? Bool ?? false
    self.showQRCode = data["showQRCode"] as? Bool ?? false

    // Billing Information
    self.billingDetails = data["billingDetails"] as? String ?? ""
    self.creditCardNumber = data["creditCardNumber"] as? String ?? ""
  }
}

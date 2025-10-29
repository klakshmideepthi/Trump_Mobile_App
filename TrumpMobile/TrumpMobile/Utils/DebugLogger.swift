import Foundation
import os.log

class DebugLogger {
  static let shared = DebugLogger()
  private let logger = Logger(subsystem: "com.telgoo5mobile.app", category: "Debug")

  private init() {}

  // Log user actions with user identification
  func logUserAction(_ action: String, for userInfo: [String: Any]) {
    let firstName = userInfo["firstName"] as? String ?? "Unknown"
    let lastName = userInfo["lastName"] as? String ?? "Unknown"
    let email = userInfo["email"] as? String ?? "Unknown"

    let userIdentifier = "\(firstName) \(lastName) (\(email))"
    logger.debug("[\(action)] User: \(userIdentifier)")

    // Log additional details in debug mode
    #if DEBUG
      print("DEBUG: [\(action)] User: \(userIdentifier)")
      for (key, value) in userInfo {
        print("DEBUG: \(key): \(value)")
      }
    #endif
  }

  // Log order-related actions
  func logOrderStep(_ step: String, for userId: String, additionalInfo: [String: Any] = [:]) {
    logger.debug("Order Step [\(step)] - User ID: \(userId)")

    #if DEBUG
      print("DEBUG: Order Step [\(step)] - User ID: \(userId)")
      for (key, value) in additionalInfo {
        print("DEBUG: \(key): \(value)")
      }
    #endif
  }

  // Log user information retrieval
  func logUserInfoRetrieval(for userIdentifier: String, context: String) {
    logger.debug("Retrieving user information - Context: \(context), User: \(userIdentifier)")

    #if DEBUG
      print("DEBUG: Retrieving user information")
      print("DEBUG: Context: \(context)")
      print("DEBUG: User: \(userIdentifier)")
    #endif
  }

  // Log user data updates
  func logUserDataUpdate(
    for userIdentifier: String, field: String, oldValue: String, newValue: String
  ) {
    logger.debug("User data update - User: \(userIdentifier), Field: \(field)")

    #if DEBUG
      print("DEBUG: User data update")
      print("DEBUG: User: \(userIdentifier)")
      print("DEBUG: Field: \(field)")
      print("DEBUG: Old Value: \(oldValue)")
      print("DEBUG: New Value: \(newValue)")
    #endif
  }

  // General debug logging
  func log(_ message: String, category: String = "General") {
    let categoryLogger = Logger(subsystem: "com.telgoo5mobile.app", category: category)
    categoryLogger.debug("\(message)")

    #if DEBUG
      print("DEBUG [\(category)]: \(message)")
    #endif
  }
}

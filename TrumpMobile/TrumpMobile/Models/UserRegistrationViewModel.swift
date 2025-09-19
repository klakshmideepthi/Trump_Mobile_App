import FirebaseAuth
import FirebaseFirestore
import Foundation
import SwiftUI

class UserRegistrationViewModel: ObservableObject {
  @Published var previousOrders: [TrumpOrder] = []

  // Helper method to get current user identifier for logging
  private func getCurrentUserIdentifier() -> String {
    let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    let identifier = name.isEmpty ? (email.isEmpty ? "Unknown User" : email) : name
    return "\(identifier) (ID: \(userId ?? "nil"))"
  }
  // Fetch previous orders for the current user
  // Calls completion with an array of orders (empty if none)
  func fetchPreviousOrders(completion: @escaping ([Any]?) -> Void) {
    let userIdentifier = getCurrentUserIdentifier()
    DebugLogger.shared.logUserInfoRetrieval(
      for: userIdentifier, context: "Fetching previous orders")

    guard let userId = userId else {
      DebugLogger.shared.log(
        "No userId available for fetching previous orders", category: "UserRegistration")
      completion(nil)
      return
    }

    let db = Firestore.firestore()
    db.collection("users").document(userId).collection("orders").getDocuments { snapshot, error in
      if let error = error {
        print("❌ Error fetching previous orders: \(error.localizedDescription)")
        DebugLogger.shared.log(
          "Error fetching previous orders for \(userIdentifier): \(error.localizedDescription)",
          category: "UserRegistration")
        completion(nil)
        return
      }
      let orders = snapshot?.documents ?? []
      DebugLogger.shared.log(
        "Successfully fetched \(orders.count) previous orders for \(userIdentifier)",
        category: "UserRegistration")
      completion(orders)
    }
  }
  // Centralized logout function with completion handling
  func logout(completion: @escaping (Bool) -> Void) {
    print("🔄 Starting logout process")

    do {
      // Sign out from Firebase Auth
      try Auth.auth().signOut()
      print("✅ Successfully signed out from Firebase")

      // Reset all user data
      resetAllUserData()

      // Remove persisted orderId
      UserDefaults.standard.removeObject(forKey: "currentOrderId")

      print("✅ Logout completed successfully")
      completion(true)

    } catch let error {
      print("❌ Error during logout: \(error.localizedDescription)")
      // Still reset local data even if Firebase signout fails
      resetAllUserData()
      UserDefaults.standard.removeObject(forKey: "currentOrderId")
      completion(false)
    }
  }

  // Legacy logout method for backward compatibility
  func logout() {
    logout { _ in }
  }
  // Reset all user-specific data (call on logout)
  func resetAllUserData() {
    accountType = ""
    email = ""
    password = ""
    confirmPassword = ""
    firstName = ""
    lastName = ""
    phoneNumber = ""
    street = ""
    aptNumber = ""
    zip = ""
    city = ""
    state = ""
    deviceBrand = ""
    deviceModel = ""
    imei = ""
    simType = ""
    numberType = ""
    selectedPhoneNumber = ""
    portInAccountNumber = ""
    portInPin = ""
    portInCurrentCarrier = ""
    portInAccountHolderName = ""
    portInSkipped = false
    isForThisDevice = true
    showQRCode = false
    creditCardNumber = ""
    billingDetails = ""
    address = ""
    country = "USA"
    deviceIsCompatible = false
    userId = nil
    orderId = nil
    isLoading = false
    errorMessage = nil
  }

  // Reset method specifically for logout (alias for resetAllUserData)
  func reset() {
    resetAllUserData()
  }
  // Step 1
  @Published var accountType: String = ""
  @Published var email: String = ""
  @Published var password: String = ""
  @Published var confirmPassword: String = ""
  // Step 2
  @Published var firstName: String = ""
  @Published var lastName: String = ""
  @Published var phoneNumber: String = ""
  @Published var street: String = ""
  @Published var aptNumber: String = ""
  @Published var zip: String = ""
  @Published var city: String = ""
  @Published var state: String = ""
  // Step 3
  @Published var deviceBrand: String = ""
  @Published var deviceModel: String = ""
  @Published var imei: String = ""
  // Step 4
  @Published var simType: String = ""
  // Step 5
  @Published var numberType: String = ""
  @Published var selectedPhoneNumber: String = ""
  // Port-in related properties
  @Published var portInAccountNumber: String = ""
  @Published var portInPin: String = ""
  @Published var portInCurrentCarrier: String = ""
  @Published var portInAccountHolderName: String = ""
  @Published var portInSkipped: Bool = false
  // eSIM related properties
  @Published var isForThisDevice: Bool = true
  @Published var showQRCode: Bool = false
  // Step 6
  @Published var creditCardNumber: String = ""
  @Published var billingDetails: String = ""
  @Published var address: String = ""
  @Published var country: String = "USA"
  @Published var deviceIsCompatible: Bool = false

  @Published var userId: String? = nil
  @Published var orderId: String? = nil  // Added order ID property
  @Published var isLoading: Bool = false
  @Published var errorMessage: String? = nil

  // Method to reset all order-specific fields for new orders
  func resetOrderSpecificFields() {
    print("🔄 Resetting order-specific fields")

    // Reset device-related fields
    deviceBrand = ""
    deviceModel = ""
    imei = ""
    deviceIsCompatible = false

    // Reset SIM and number selection
    simType = ""
    // DO NOT reset numberType until order is actually completed
    // numberType = "" // Keep this for step 6 logic
    selectedPhoneNumber = ""

    // Reset port-in related fields
    portInAccountNumber = ""
    portInPin = ""
    portInCurrentCarrier = ""
    portInAccountHolderName = ""
    portInSkipped = false

    // Reset eSIM related fields
    isForThisDevice = true
    showQRCode = false

    // Reset billing information
    creditCardNumber = ""
    billingDetails = ""
    address = ""
    country = "USA"

    // Do NOT clear orderId here; let completeOrder handle it after completion
    UserDefaults.standard.removeObject(forKey: "currentOrderId")

    print("✅ Order-specific fields reset complete (preserving numberType: \(numberType))")
  }

  // Method to completely reset ALL fields including numberType after order completion
  func completeOrderReset() {
    print("🔄 Complete order reset including numberType")

    // Reset device-related fields
    deviceBrand = ""
    deviceModel = ""
    imei = ""
    deviceIsCompatible = false

    // Reset SIM and number selection (including numberType)
    simType = ""
    numberType = ""  // Now we reset this too
    selectedPhoneNumber = ""

    // Reset port-in related fields
    portInAccountNumber = ""
    portInPin = ""
    portInCurrentCarrier = ""
    portInAccountHolderName = ""
    portInSkipped = false

    // Reset eSIM related fields
    isForThisDevice = true
    showQRCode = false

    // Reset billing information
    creditCardNumber = ""
    billingDetails = ""
    address = ""
    country = "USA"

    // Clear orderId and UserDefaults
    orderId = nil
    UserDefaults.standard.removeObject(forKey: "currentOrderId")

    print("✅ Complete order reset finished")
  }

  // Save current step data to Firebase
  func saveCurrentStepData(stepData: [String: Any], completion: @escaping (Bool) -> Void) {
    isLoading = true
    errorMessage = nil

    // If user isn't created yet, we'll just keep the data locally until we create the account
    guard let userId = userId else {
      isLoading = false
      completion(true)
      return
    }

    let dispatchGroup = DispatchGroup()
    var errors: [String] = []

    // Always save to the user's main document
    dispatchGroup.enter()
    FirebaseManager.shared.updateUserRegistration(userId: userId, data: stepData) {
      success, error in
      if !success {
        if let error = error {
          errors.append("Failed to update user data: \(error.localizedDescription)")
        } else {
          errors.append("Failed to update user data")
        }
      }
      dispatchGroup.leave()
    }

    // If we have an orderId, also update the order document
    if let orderId = orderId {
      dispatchGroup.enter()
      let db = Firestore.firestore()
      db.collection("users").document(userId)
        .collection("orders").document(orderId)
        .updateData(stepData) { error in
          if let error = error {
            print("❌ Error updating order data: \(error.localizedDescription)")
            errors.append("Failed to update order data: \(error.localizedDescription)")
          } else {
            print("✅ Successfully updated order data")
          }
          dispatchGroup.leave()
        }
    }

    // When all save operations complete
    dispatchGroup.notify(queue: .main) { [weak self] in
      guard let self = self else { return }

      self.isLoading = false
      if errors.isEmpty {
        completion(true)
      } else {
        self.errorMessage = errors.joined(separator: "; ")
        completion(false)
      }
    }
  }

  // Create user account
  func createUserAccount(completion: @escaping (Bool) -> Void) {
    guard !email.isEmpty, !password.isEmpty else {
      errorMessage = "Email and password are required"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
      guard let self = self else { return }

      if let error = error {
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = error.localizedDescription
          completion(false)
        }
        return
      }

      guard let user = result?.user else {
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = "Failed to create user account"
          completion(false)
        }
        return
      }

      self.userId = user.uid

      // Save initial user data
      let initialData: [String: Any] = [
        "userId": user.uid,
        "accountType": self.accountType,
        "email": self.email,
        "createdAt": FieldValue.serverTimestamp(),
      ]

      FirebaseManager.shared.saveUserRegistration(userId: user.uid, data: initialData) {
        success, error in
        DispatchQueue.main.async {
          self.isLoading = false
          if let error = error {
            self.errorMessage = error.localizedDescription
            completion(false)
          } else {
            completion(true)
          }
        }
      }
    }
  }

  // Sign in with email
  func signIn(completion: @escaping (Bool) -> Void) {
    DebugLogger.shared.log("Attempting sign in for email: \(email)", category: "Authentication")

    isLoading = true
    errorMessage = nil

    Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
      guard let self = self else { return }

      if let error = error {
        DebugLogger.shared.log(
          "Sign in failed for email \(self.email): \(error.localizedDescription)",
          category: "Authentication")
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = error.localizedDescription
          completion(false)
        }
        return
      }

      guard let user = result?.user else {
        DebugLogger.shared.log(
          "Sign in failed for email \(self.email): No user returned", category: "Authentication")
        DispatchQueue.main.async {
          self.isLoading = false
          self.errorMessage = "Failed to sign in"
          completion(false)
        }
        return
      }

      self.userId = user.uid
      let userIdentifier = self.getCurrentUserIdentifier()
      DebugLogger.shared.log("Sign in successful for \(userIdentifier)", category: "Authentication")

      self.loadUserData { success in
        DispatchQueue.main.async {
          self.isLoading = false
          completion(success)
        }
      }
    }
  }

  // Load user data
  func loadUserData(completion: @escaping (Bool) -> Void) {
    guard let userId = userId else {
      DebugLogger.shared.log(
        "No userId available for loading user data", category: "UserRegistration")
      completion(false)
      return
    }

    // Get the authenticated user's email
    let authenticatedEmail = Auth.auth().currentUser?.email ?? ""
    let userIdentifier = getCurrentUserIdentifier()

    DebugLogger.shared.logUserInfoRetrieval(
      for: userIdentifier, context: "Loading user data on sign in")

    isLoading = true
    errorMessage = nil

    let group = DispatchGroup()

    // Load only main user data and contact info, not order-specific data
    group.enter()
    FirebaseManager.shared.getUserRegistration(userId: userId) { [weak self] data, error in
      defer { group.leave() }
      guard let self = self else { return }

      if let error = error {
        DispatchQueue.main.async {
          self.errorMessage = error.localizedDescription
        }
        return
      }

      if let data = data {
        DispatchQueue.main.async {
          // Update only non-order specific properties
          self.accountType = data["accountType"] as? String ?? ""
          // Use authenticated email as fallback if not stored in Firebase
          self.email = data["email"] as? String ?? authenticatedEmail
          // Do not load device, SIM, phone number, or billing info from main document
        }
      } else {
        // If no stored data, use the authenticated user's email
        DispatchQueue.main.async {
          self.email = authenticatedEmail
        }
      }
    }

    // Load contact info
    group.enter()
    FirebaseManager.shared.getContactInfo(userId: userId) { [weak self] data, error in
      defer { group.leave() }
      guard let self = self, let data = data else { return }

      DispatchQueue.main.async {
        // Update contact properties - these should be auto-filled
        self.firstName = data["firstName"] as? String ?? self.firstName
        self.lastName = data["lastName"] as? String ?? self.lastName
        self.phoneNumber = data["phoneNumber"] as? String ?? self.phoneNumber
      }
    }

    // Load shipping address
    group.enter()
    FirebaseManager.shared.getShippingAddress(userId: userId) { [weak self] data, error in
      defer { group.leave() }
      guard let self = self, let data = data else { return }

      DispatchQueue.main.async {
        // Update address properties - these should be auto-filled
        self.street = data["street"] as? String ?? self.street
        self.aptNumber = data["aptNumber"] as? String ?? self.aptNumber
        self.zip = data["zip"] as? String ?? self.zip
        self.city = data["city"] as? String ?? self.city
        self.state = data["state"] as? String ?? self.state
      }
    }

    // Do NOT load previous order-specific info like device info, SIM selection, etc.
    // Reset order-specific fields to ensure they start fresh
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }

      // Use the new reset method for cleaner code
      self.resetOrderSpecificFields()
    }

    // When all data is loaded
    group.notify(queue: .main) { [weak self] in
      guard let self = self else { return }
      self.isLoading = false
      completion(true)
    }
  }

  // Save contact information to contactInfo, shippingAddress, and orders collections
  func saveContactInfo(completion: @escaping (Bool) -> Void) {
    let userIdentifier = getCurrentUserIdentifier()

    print(
      "🔍 saveContactInfo called with firstName: \(firstName), lastName: \(lastName), phoneNumber: \(phoneNumber)"
    )

    DebugLogger.shared.logUserAction(
      "Saving Contact Info",
      for: [
        "firstName": firstName,
        "lastName": lastName,
        "phoneNumber": phoneNumber,
        "email": email,
        "userId": userId ?? "nil",
      ])

    guard let userId = userId else {
      errorMessage = "User ID not available"
      print("❌ Error: User ID not available")
      DebugLogger.shared.log(
        "Error: User ID not available when saving contact info for \(userIdentifier)",
        category: "UserRegistration")
      completion(false)
      return
    }

    // Get the authenticated user's email
    let authenticatedEmail = Auth.auth().currentUser?.email ?? ""
    let emailToSave = email.isEmpty ? authenticatedEmail : email

    print("👤 Using userId: \(userId)")
    print("📧 Email to save: \(emailToSave)")
    isLoading = true
    errorMessage = nil

    // Create contact-only data for contactInfo collection
    let contactData: [String: Any] = [
      "userId": userId,
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phoneNumber,
      "email": emailToSave,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Create shipping address data for shippingAddress collection
    let shippingAddressData: [String: Any] = [
      "userId": userId,
      "street": street,
      "aptNumber": aptNumber,
      "zip": zip,
      "city": city,
      "state": state,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Create order data that includes contact and shipping information
    let orderData: [String: Any] = [
      "userId": userId,
      "firstName": firstName,
      "lastName": lastName,
      "phoneNumber": phoneNumber,
      "email": emailToSave,
      "street": street,
      "aptNumber": aptNumber,
      "zip": zip,
      "city": city,
      "state": state,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Track completion of all save operations
    let dispatchGroup = DispatchGroup()
    var saveErrors: [String] = []

    // 1. Save to contactInfo collection
    dispatchGroup.enter()
    print("🔄 Saving to contactInfo collection...")
    FirebaseManager.shared.saveContactInfo(userId: userId, contactData: contactData) {
      success, error in
      print("📌 Contact info save result: \(success)")
      if !success {
        if let error = error {
          saveErrors.append("Failed to save contact info: \(error.localizedDescription)")
          print("❌ Contact info save error: \(error.localizedDescription)")
        } else {
          saveErrors.append("Failed to save contact info")
          print("❌ Contact info save failed without error")
        }
      }
      dispatchGroup.leave()
    }

    // 2. Save to shippingAddress collection
    dispatchGroup.enter()
    print("🔄 Saving to shippingAddress collection...")
    FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: shippingAddressData) {
      success, error in
      print("📌 Shipping address save result: \(success)")
      if !success {
        if let error = error {
          saveErrors.append("Failed to save shipping address: \(error.localizedDescription)")
          print("❌ Shipping address save error: \(error.localizedDescription)")
        } else {
          saveErrors.append("Failed to save shipping address")
          print("❌ Shipping address save failed without error")
        }
      }
      dispatchGroup.leave()
    }

    // 3. Save to orders collection
    dispatchGroup.enter()
    print("🔄 Saving to orders collection...")

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      print("❌ Error: No order ID available for saving contact info")
      saveErrors.append("Order ID not available - please restart order process")
      dispatchGroup.leave()
      return
    }

    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(orderData, merge: true) { error in
        if let error = error {
          print("❌ Error saving contact and shipping info to order: \(error.localizedDescription)")
          saveErrors.append("Failed to save info to order")
        } else {
          print("✅ Successfully saved contact and shipping info to order")
        }
        dispatchGroup.leave()
      }

    // When all save operations complete
    dispatchGroup.notify(queue: .main) { [weak self] in
      guard let self = self else {
        print("❌ Self is nil in completion handler")
        return
      }

      self.isLoading = false

      if saveErrors.isEmpty {
        // All saves successful
        print("✅ Successfully saved contact information to all collections")
        completion(true)
      } else {
        // Some saves failed
        self.errorMessage = saveErrors.joined(separator: "; ")
        print("❌ Error saving contact information: \(self.errorMessage ?? "Unknown error")")
        completion(false)
      }

      // Let's debug the state after save
      FirebaseManager.shared.debugUserDataLocations(userId: userId) { results in
        print("📊 Debug user data locations:")

        if let contactInfoExists = results["contactInfoExists"] as? Bool {
          print("  - Contact info exists: \(contactInfoExists)")
          if contactInfoExists, let data = results["contactInfoData"] as? [String: Any] {
            print("  - Contact info firstName: \(data["firstName"] ?? "nil")")
            print("  - Contact info lastName: \(data["lastName"] ?? "nil")")
            print("  - Contact info phoneNumber: \(data["phoneNumber"] ?? "nil")")
          }
        }

        if let shippingAddressExists = results["shippingAddressExists"] as? Bool {
          print("  - Shipping address exists: \(shippingAddressExists)")
        }
      }
    }
  }

  // Save device information directly to orders collection
  func saveDeviceInfo(completion: @escaping (Bool) -> Void) {
    guard let userId = userId else {
      errorMessage = "User ID not available"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    let deviceData: [String: Any] = [
      "userId": userId,
      "deviceBrand": deviceBrand,
      "deviceModel": deviceModel,
      "imei": imei,
      "deviceIsCompatible": deviceIsCompatible,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      self.isLoading = false
      self.errorMessage = "Order ID not available - please restart order process"
      print("❌ Error: No order ID available for saving device info")
      completion(false)
      return
    }

    // Save directly to orders collection
    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(deviceData, merge: true) { error in
        self.isLoading = false

        if let error = error {
          self.errorMessage = error.localizedDescription
          print("❌ Error saving device info to order: \(error.localizedDescription)")
          completion(false)
        } else {
          print("✅ Successfully saved device info to order")
          completion(true)
        }
      }
  }

  // Save SIM selection directly to orders
  func saveSimSelection(completion: @escaping (Bool) -> Void) {
    guard let userId = userId else {
      errorMessage = "User ID not available"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    let simData: [String: Any] = [
      "userId": userId,
      "simType": simType,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      self.isLoading = false
      self.errorMessage = "Order ID not available - please restart order process"
      print("❌ Error: No order ID available for saving SIM selection")
      completion(false)
      return
    }

    // Save directly to orders collection
    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(simData, merge: true) { error in
        self.isLoading = false

        if let error = error {
          self.errorMessage = error.localizedDescription
          print("❌ Error saving SIM info to order: \(error.localizedDescription)")
          completion(false)
        } else {
          print("✅ Successfully saved SIM info to order")
          completion(true)
        }
      }
  }

  // Save number selection directly to orders
  func saveNumberSelection(completion: @escaping (Bool) -> Void) {
    guard let userId = userId else {
      errorMessage = "User ID not available"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    var numberData: [String: Any] = [
      "userId": userId,
      "numberType": numberType,
      "selectedPhoneNumber": selectedPhoneNumber,
      "portInSkipped": portInSkipped,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Add port-in data if transferring existing number
    if numberType == "Existing" {
      numberData["portInAccountNumber"] = portInAccountNumber
      numberData["portInPin"] = portInPin
      numberData["portInCurrentCarrier"] = portInCurrentCarrier
      numberData["portInAccountHolderName"] = portInAccountHolderName
    }

    // Add eSIM data if applicable
    if simType == "eSIM" && numberType == "New" {
      numberData["isForThisDevice"] = isForThisDevice
      numberData["showQRCode"] = showQRCode
    }

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      self.isLoading = false
      self.errorMessage = "Order ID not available - please restart order process"
      print("❌ Error: No order ID available for saving number selection")
      completion(false)
      return
    }

    // Save directly to orders collection
    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(numberData, merge: true) { error in
        self.isLoading = false

        if let error = error {
          self.errorMessage = error.localizedDescription
          print("❌ Error saving number selection to order: \(error.localizedDescription)")
          completion(false)
        } else {
          print("✅ Successfully saved number selection to order")
          completion(true)
        }
      }
  }

  // Save shipping address information directly to orders and shippingAddress collection
  func saveShippingAddress(completion: @escaping (Bool) -> Void) {
    print(
      "🔍 saveShippingAddress called with street: \(street), city: \(city), state: \(state), zip: \(zip)"
    )

    guard let userId = userId else {
      errorMessage = "User ID not available"
      print("❌ Error: User ID not available")
      completion(false)
      return
    }

    print("👤 Using userId: \(userId)")
    isLoading = true
    errorMessage = nil

    // Create shipping address data
    let shippingAddressData: [String: Any] = [
      "userId": userId,
      "street": street,
      "aptNumber": aptNumber,
      "zip": zip,
      "city": city,
      "state": state,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Track completion of all save operations
    let dispatchGroup = DispatchGroup()
    var saveErrors: [String] = []

    // 1. Save to shippingAddress collection
    dispatchGroup.enter()
    print("🔄 Saving to shippingAddress collection...")
    FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: shippingAddressData) {
      success, error in
      print("📌 Shipping address save result: \(success)")
      if !success {
        if let error = error {
          saveErrors.append("Failed to save shipping address: \(error.localizedDescription)")
          print("❌ Shipping address save error: \(error.localizedDescription)")
        } else {
          saveErrors.append("Failed to save shipping address")
          print("❌ Shipping address save failed without error")
        }
      }
      dispatchGroup.leave()
    }

    // 2. Save to orders collection
    dispatchGroup.enter()
    print("🔄 Saving to orders collection...")

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      print("❌ Error: No order ID available for saving shipping address")
      saveErrors.append("Order ID not available - please restart order process")
      dispatchGroup.leave()
      return
    }

    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(shippingAddressData, merge: true) { error in
        if let error = error {
          print("❌ Error saving shipping address to order: \(error.localizedDescription)")
          saveErrors.append("Failed to save shipping address to order")
        } else {
          print("✅ Successfully saved shipping address to order")
        }
        dispatchGroup.leave()
      }

    // When all save operations complete
    dispatchGroup.notify(queue: .main) { [weak self] in
      guard let self = self else {
        print("❌ Self is nil in completion handler")
        return
      }

      self.isLoading = false

      if saveErrors.isEmpty {
        // All saves successful
        print("✅ Successfully saved shipping address to all collections")
        completion(true)
      } else {
        // Some saves failed
        self.errorMessage = saveErrors.joined(separator: "; ")
        print("❌ Error saving shipping address: \(self.errorMessage ?? "Unknown error")")
        completion(false)
      }

      // Debug check for shipping address
      FirebaseManager.shared.debugUserDataLocations(userId: userId) { results in
        print("📊 Debug shipping address data:")

        if let shippingAddressExists = results["shippingAddressExists"] as? Bool {
          print("  - Shipping address exists: \(shippingAddressExists)")
          if shippingAddressExists, let data = results["shippingAddressData"] as? [String: Any] {
            print("  - Street: \(data["street"] ?? "nil")")
            print("  - City: \(data["city"] ?? "nil")")
            print("  - State: \(data["state"] ?? "nil")")
            print("  - Zip: \(data["zip"] ?? "nil")")
          }
        }
      }
    }
  }

  // Save billing information directly to orders
  func saveBillingInfo(completion: @escaping (Bool) -> Void) {
    guard let userId = userId else {
      errorMessage = "User ID not available"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    // Combine all billing data to save directly to orders
    let billingData: [String: Any] = [
      "userId": userId,
      "creditCardNumber": creditCardNumber,
      "billingDetails": billingDetails,
      "address": address,
      "country": country,
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    // Check if order ID exists - if not, this is an error
    guard let orderId = self.orderId else {
      self.isLoading = false
      self.errorMessage = "Order ID not available - please restart order process"
      print("❌ Error: No order ID available for saving billing info")
      completion(false)
      return
    }

    // Save directly to orders collection
    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(billingData, merge: true) { error in
        self.isLoading = false

        if let error = error {
          self.errorMessage = error.localizedDescription
          print("❌ Error saving billing info to order: \(error.localizedDescription)")
          completion(false)
        } else {
          print("✅ Successfully saved billing info to order")
          completion(true)
        }
      }
  }

  // Save final order
  func completeOrder(completion: @escaping (Bool) -> Void) {
    guard let userId = userId, let orderId = orderId else {
      errorMessage = "User ID or Order ID not available"
      completion(false)
      return
    }

    isLoading = true
    errorMessage = nil

    let orderData: [String: Any] = [
      "userId": userId,
      "orderCompleted": true,
      "orderCompletionDate": FieldValue.serverTimestamp(),
      "status": "completed",
    ]

    // Save directly to orders collection only
    let db = Firestore.firestore()
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(orderData, merge: true) { [weak self] error in
        guard let self = self else { return }
        self.isLoading = false
        if let error = error {
          self.errorMessage = error.localizedDescription
          print("❌ Error completing order: \(error.localizedDescription)")
          completion(false)
        } else {
          print("✅ Successfully completed order")
          // After marking as completed, do complete reset including numberType
          self.completeOrderReset()
          completion(true)
        }
      }
  }
}

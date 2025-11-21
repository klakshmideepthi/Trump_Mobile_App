import Firebase
import FirebaseFirestore
import Foundation

class FirebaseManager {
  static let shared = FirebaseManager()
  private let db = Firestore.firestore()

  // Save user registration data
  func saveUserRegistration(
    userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void
  ) {
    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = data
    dataWithUserId["userId"] = userId

    db.collection("users").document(userId).setData(dataWithUserId) { error in
      completion(error == nil, error)
    }
  }

  // Create a new order for a user
  func createNewOrder(userId: String, planId: Int? = nil, planName: String? = nil, planPrice: Int? = nil, completion: @escaping (String?, Error?) -> Void) {
    // Create a new document reference with auto-generated ID
    let orderRef = db.collection("users").document(userId).collection("orders").document()
    let orderId = orderRef.documentID

    // Create initial order data with userId for security rules
    var orderData: [String: Any] = [
      "orderId": orderId,
      "userId": userId,
      // Use 'pending' to align with in-progress state checks
      "status": "pending",
      "currentStep": 1,
      "createdAt": FieldValue.serverTimestamp(),
      "updatedAt": FieldValue.serverTimestamp(),
    ]
    
    // Add plan information if provided
    if let planId = planId {
      orderData["plan_id"] = planId
    }
    if let planName = planName {
      orderData["planName"] = planName
    }
    if let planPrice = planPrice {
      orderData["planPrice"] = planPrice
      orderData["amount"] = Double(planPrice)
    }

    // Save the new order document
    orderRef.setData(orderData) { error in
      if let error = error {
        print("❌ Error creating order: \(error.localizedDescription)")
        completion(nil, error)
      } else {
        print("✅ Order created with ID: \(orderId)")
        completion(orderId, nil)
      }
    }
  }

  // Copy contact info from user to order
  func copyContactInfoToOrder(
    userId: String, orderId: String, completion: @escaping (Bool, Error?) -> Void
  ) {
    // Get user's contact info
    db.collection("users").document(userId).collection("contactInfo").document("primary")
      .getDocument { snapshot, error in
        if let error = error {
          print("❌ Error getting contact info: \(error.localizedDescription)")
          completion(false, error)
          return
        }

        guard let data = snapshot?.data(), !data.isEmpty else {
          print("⚠️ No contact info found to copy")
          completion(true, nil)  // Still succeed if no data to copy
          return
        }

        // Use the new method to save to order without updating the user default (since we're copying from it)
        self.saveOrderContactInfo(
          userId: userId, orderId: orderId, contactData: data, updateUserDefault: false
        ) { success, error in
          if success {
            print("✅ Contact info copied to order")
            completion(true, nil)
          } else {
            print(
              "❌ Error copying contact info to order: \(error?.localizedDescription ?? "unknown")")
            completion(false, error)
          }
        }
      }
  }

  // Copy shipping address from user to order
  func copyShippingAddressToOrder(
    userId: String, orderId: String, completion: @escaping (Bool, Error?) -> Void
  ) {
    // Get user's shipping address
    db.collection("users").document(userId).collection("shippingAddresses").document("primary")
      .getDocument { snapshot, error in
        if let error = error {
          print("❌ Error getting shipping address: \(error.localizedDescription)")
          completion(false, error)
          return
        }

        guard let data = snapshot?.data(), !data.isEmpty else {
          print("⚠️ No shipping address found to copy")
          completion(true, nil)  // Still succeed if no data to copy
          return
        }

        // Use the new method to save to order without updating the user default (since we're copying from it)
        self.saveOrderShippingAddress(
          userId: userId, orderId: orderId, addressData: data, updateUserDefault: false
        ) { success, error in
          if success {
            print("✅ Shipping address copied to order")
            completion(true, nil)
          } else {
            print(
              "❌ Error copying shipping address to order: \(error?.localizedDescription ?? "unknown")"
            )
            completion(false, error)
          }
        }
      }
  }

  // Update user registration data
  func updateUserRegistration(
    userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void
  ) {
    print("📝 updateUserRegistration called for userId: \(userId)")
    print("📝 Data to update: \(data)")

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = data
    dataWithUserId["userId"] = userId

    let userRef = db.collection("users").document(userId)

    // Check if document exists first
    userRef.getDocument { (document, error) in
      if let error = error {
        print("❌ Error checking if document exists: \(error.localizedDescription)")
        completion(false, error)
        return
      }

      if document?.exists == true {
        print("📄 Document exists, updating it")
        // Document exists, update it
        userRef.updateData(dataWithUserId) { error in
          if let error = error {
            print("❌ Error updating document: \(error.localizedDescription)")
            completion(false, error)
          } else {
            print("✅ Document updated successfully")
            completion(true, nil)
          }
        }
      } else {
        print("📄 Document doesn't exist, creating it")
        // Document doesn't exist, create it
        userRef.setData(dataWithUserId, merge: true) { error in
          if let error = error {
            print("❌ Error creating document: \(error.localizedDescription)")
            completion(false, error)
          } else {
            print("✅ Document created successfully")
            completion(true, nil)
          }
        }
      }
    }
  }

  // Get user registration data
  func getUserRegistration(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
    db.collection("users").document(userId).getDocument { snapshot, error in
      if let error = error {
        completion(nil, error)
        return
      }

      guard let data = snapshot?.data() else {
        completion(nil, nil)
        return
      }

      completion(data, nil)
    }
  }

  // Save contact information separately
  func saveContactInfo(
    userId: String, contactData: [String: Any], completion: @escaping (Bool, Error?) -> Void
  ) {
    print("📞 saveContactInfo called for userId: \(userId)")
    print("📞 contactData: \(contactData)")

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = contactData
    dataWithUserId["userId"] = userId

    // Save to users/{userId}/contactInfo/primary subcollection
    db.collection("users").document(userId)
      .collection("contactInfo").document("primary")
      .setData(dataWithUserId, merge: true) { error in
        if let error = error {
          print("❌ Error saving contact info: \(error.localizedDescription)")
          completion(false, error)
        } else {
          print("✅ Contact info saved successfully")
          completion(true, nil)
        }
      }
  }

  // Save shipping address separately
  func saveShippingAddress(
    userId: String, addressData: [String: Any], completion: @escaping (Bool, Error?) -> Void
  ) {
    print("📍 saveShippingAddress called for userId: \(userId)")
    print("📍 addressData: \(addressData)")

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = addressData
    dataWithUserId["userId"] = userId

    // Save to users/{userId}/shippingAddress/primary subcollection
    db.collection("users").document(userId)
      .collection("shippingAddress").document("primary")
      .setData(dataWithUserId, merge: true) { error in
        if let error = error {
          print("❌ Error saving shipping address: \(error.localizedDescription)")
          completion(false, error)
        } else {
          print("✅ Shipping address saved successfully")
          completion(true, nil)
        }
      }
  }

  // Save billing address directly to orders
  func saveBillingAddress(
    userId: String, addressData: [String: Any], completion: @escaping (Bool, Error?) -> Void
  ) {
    // Get the current order ID - if none exists, this is an error
    guard let orderId = UserDefaults.standard.string(forKey: "currentOrderId") else {
      let error = NSError(
        domain: "FirebaseManager", code: 1001,
        userInfo: [
          NSLocalizedDescriptionKey: "Order ID not available - please restart order process"
        ])
      completion(false, error)
      return
    }

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = addressData
    dataWithUserId["userId"] = userId

    // Add billing info to the order document
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(dataWithUserId, merge: true) { error in
        completion(error == nil, error)
      }
  }

  // Get contact information
  func getContactInfo(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
    print("📱 getContactInfo called for userId: \(userId)")

    db.collection("users").document(userId)
      .collection("contactInfo").document("primary")
      .getDocument { snapshot, error in
        if let error = error {
          print("❌ Error getting contact info: \(error.localizedDescription)")
          completion(nil, error)
          return
        }

        if snapshot?.exists == false {
          print("⚠️ Contact info document does not exist")
          completion(nil, nil)
          return
        }

        guard let data = snapshot?.data() else {
          print("⚠️ Contact info document exists but has no data")
          completion(nil, nil)
          return
        }

        print("✅ Successfully retrieved contact info: \(data)")
        completion(data, nil)
      }
  }

  // Get shipping address
  func getShippingAddress(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
    db.collection("users").document(userId)
      .collection("shippingAddress").document("primary")
      .getDocument { snapshot, error in
        if let error = error {
          completion(nil, error)
          return
        }

        guard let data = snapshot?.data() else {
          completion(nil, nil)
          return
        }

        completion(data, nil)
      }
  }

  // Get billing address from orders
  func getBillingAddress(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
    // Get the current order ID - if none exists, this is an error
    guard let orderId = UserDefaults.standard.string(forKey: "currentOrderId") else {
      let error = NSError(
        domain: "FirebaseManager", code: 1002,
        userInfo: [
          NSLocalizedDescriptionKey: "Order ID not available - please restart order process"
        ])
      completion(nil, error)
      return
    }

    // Get billing info from the order document
    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .getDocument { snapshot, error in
        if let error = error {
          completion(nil, error)
          return
        }

        guard let data = snapshot?.data() else {
          completion(nil, nil)
          return
        }

        // Extract only billing-related fields
        var billingData: [String: Any] = [:]
        let billingFields = [
          "address", "country", "creditCardNumber", "billingDetails", "billingCity", "billingState",
        ]

        for field in billingFields {
          if let value = data[field] {
            billingData[field] = value
          }
        }

        completion(billingData, nil)
      }
  }

  // Save contact information directly to a specific order
  func saveOrderContactInfo(
    userId: String, orderId: String, contactData: [String: Any], updateUserDefault: Bool = true,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    print("📞 saveOrderContactInfo called for orderId: \(orderId)")
    print("📞 contactData: \(contactData)")

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = contactData
    dataWithUserId["userId"] = userId

    let orderRef = db.collection("users").document(userId)
      .collection("orders").document(orderId)

    // Save contact data directly to the order document
    orderRef.setData(dataWithUserId, merge: true) { error in
      if let error = error {
        print("❌ Error saving order contact info: \(error.localizedDescription)")
        completion(false, error)
        return
      }

      print("✅ Order contact info saved successfully")

      // If updateUserDefault is true, also update the user's default contact info
      if updateUserDefault {
        self.saveContactInfo(userId: userId, contactData: contactData) { success, error in
          if let error = error {
            print(
              "⚠️ Updated order contact but failed to sync with user default: \(error.localizedDescription)"
            )
          } else {
            print("✅ Successfully synced order contact with user default")
          }
          completion(true, nil)  // We still consider the operation successful if the order update worked
        }
      } else {
        completion(true, nil)
      }
    }
  }

  // Save shipping address directly to a specific order
  func saveOrderShippingAddress(
    userId: String, orderId: String, addressData: [String: Any], updateUserDefault: Bool = true,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    print("📍 saveOrderShippingAddress called for orderId: \(orderId)")
    print("📍 addressData: \(addressData)")

    // Ensure userId is included in the data for Firestore security rules
    var dataWithUserId = addressData
    dataWithUserId["userId"] = userId

    let orderRef = db.collection("users").document(userId)
      .collection("orders").document(orderId)

    // Save shipping address data directly to the order document
    orderRef.setData(dataWithUserId, merge: true) { error in
      if let error = error {
        print("❌ Error saving order shipping address: \(error.localizedDescription)")
        completion(false, error)
        return
      }

      print("✅ Order shipping address saved successfully")

      // If updateUserDefault is true, also update the user's default shipping address
      if updateUserDefault {
        self.saveShippingAddress(userId: userId, addressData: addressData) { success, error in
          if let error = error {
            print(
              "⚠️ Updated order shipping address but failed to sync with user default: \(error.localizedDescription)"
            )
          } else {
            print("✅ Successfully synced order shipping address with user default")
          }
          completion(true, nil)  // We still consider the operation successful if the order update worked
        }
      } else {
        completion(true, nil)
      }
    }
  }

  // Get contact information directly from a specific order
  func getOrderContactInfo(
    userId: String, orderId: String, completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    print("📱 getOrderContactInfo called for orderId: \(orderId)")

    let orderRef = db.collection("users").document(userId)
      .collection("orders").document(orderId)

    orderRef.getDocument { snapshot, error in
      if let error = error {
        print("❌ Error getting order document: \(error.localizedDescription)")
        completion(nil, error)
        return
      }

      if snapshot?.exists == false {
        print("⚠️ Order document does not exist")
        completion(nil, nil)
        return
      }

      guard let data = snapshot?.data() else {
        print("⚠️ Order document exists but has no data")
        completion(nil, nil)
        return
      }

      // Extract only contact-related fields
      var contactData: [String: Any] = [:]
      let contactFields = ["firstName", "lastName", "phoneNumber", "email"]

      for field in contactFields {
        if let value = data[field] {
          contactData[field] = value
        }
      }

      print("✅ Successfully retrieved order contact info")
      completion(contactData, nil)
    }
  }

  // Get shipping address directly from a specific order
  func getOrderShippingAddress(
    userId: String, orderId: String, completion: @escaping ([String: Any]?, Error?) -> Void
  ) {
    print("📱 getOrderShippingAddress called for orderId: \(orderId)")

    let orderRef = db.collection("users").document(userId)
      .collection("orders").document(orderId)

    orderRef.getDocument { snapshot, error in
      if let error = error {
        print("❌ Error getting order document: \(error.localizedDescription)")
        completion(nil, error)
        return
      }

      if snapshot?.exists == false {
        print("⚠️ Order document does not exist")
        completion(nil, nil)
        return
      }

      guard let data = snapshot?.data() else {
        print("⚠️ Order document exists but has no data")
        completion(nil, nil)
        return
      }

      // Extract only shipping address-related fields
      var shippingData: [String: Any] = [:]
      let shippingFields = ["street", "aptNumber", "zip", "city", "state"]

      for field in shippingFields {
        if let value = data[field] {
          shippingData[field] = value
        }
      }

      print("✅ Successfully retrieved order shipping address")
      completion(shippingData, nil)
    }
  }

  // Delete an order from Firebase
  func deleteOrder(userId: String, orderId: String, completion: @escaping (Bool, Error?) -> Void) {
    print("DEBUG: FirebaseManager.deleteOrder called")
    print("DEBUG: Attempting to delete order with ID: \(orderId) for user: \(userId)")

    let orderRef = db.collection("users").document(userId).collection("orders").document(orderId)

    // First check if document exists
    orderRef.getDocument { (docSnapshot, error) in
      if let error = error {
        print("DEBUG: Error checking if order exists: \(error.localizedDescription)")
        completion(false, error)
        return
      }

      guard let docSnapshot = docSnapshot else {
        print("DEBUG: Document snapshot is nil")
        completion(false, nil)
        return
      }

      if docSnapshot.exists {
        print("DEBUG: Order document exists, proceeding with deletion")

        orderRef.delete { error in
          if let error = error {
            print("DEBUG: Error deleting order: \(error.localizedDescription)")
            completion(false, error)
          } else {
            print("DEBUG: Order successfully deleted from Firestore")
            completion(true, nil)
          }
        }
      } else {
        print("DEBUG: Order document does not exist in Firestore")
        // Still return true since the end result is the same (no order exists)
        completion(true, nil)
      }
    }
  }

  // Debug function to check where user data is stored
  func debugUserDataLocations(userId: String, completion: @escaping ([String: Any]) -> Void) {
    var results: [String: Any] = [:]
    let dispatchGroup = DispatchGroup()

    // Check main user document
    dispatchGroup.enter()
    db.collection("users").document(userId).getDocument { snapshot, error in
      defer { dispatchGroup.leave() }

      if let error = error {
        results["mainDocError"] = error.localizedDescription
      } else if let data = snapshot?.data() {
        results["mainDocExists"] = true
        results["mainDocData"] = data
      } else {
        results["mainDocExists"] = false
      }
    }

    // Check contact info subcollection
    dispatchGroup.enter()
    db.collection("users").document(userId).collection("contactInfo").document("primary")
      .getDocument { snapshot, error in
        defer { dispatchGroup.leave() }

        if let error = error {
          results["contactInfoError"] = error.localizedDescription
        } else if let data = snapshot?.data() {
          results["contactInfoExists"] = true
          results["contactInfoData"] = data
        } else {
          results["contactInfoExists"] = false
        }
      }

    // Check shipping address subcollection
    dispatchGroup.enter()
    db.collection("users").document(userId).collection("shippingAddress").document("primary")
      .getDocument { snapshot, error in
        defer { dispatchGroup.leave() }

        if let error = error {
          results["shippingAddressError"] = error.localizedDescription
        } else if let data = snapshot?.data() {
          results["shippingAddressExists"] = true
          results["shippingAddressData"] = data
        } else {
          results["shippingAddressExists"] = false
        }
      }

    // When all checks are complete
    dispatchGroup.notify(queue: .main) {
      completion(results)
    }
  }

  // MARK: - Plan Caching
  
  /// Save plans to Firestore, keyed by zip code, enrollment type, and family plan status
  func savePlans(
    zipCode: String,
    enrollmentType: String,
    isFamilyPlan: String,
    plans: [Plan],
    completion: @escaping (Bool, Error?) -> Void
  ) {
    // Create a document ID based on zip code, enrollment type, and family plan status
    let documentId = "\(zipCode)_\(enrollmentType)_\(isFamilyPlan)"
    
    // Convert plans to dictionary array
    var plansData: [[String: Any]] = []
    for plan in plans {
      var planDict: [String: Any] = [
        "plan_id": plan.plan_id,
        "plan_name": plan.plan_name,
        "plan_price": plan.plan_price,
        "total_plan_price": plan.total_plan_price,
        "plan_description": plan.plan_description,
        "plan_code": plan.plan_code,
        "display_name": plan.display_name as Any,
        "display_price": plan.display_price,
        "display_description": plan.display_description as Any,
        "display_features_description": plan.display_features_description,
        "data": plan.data,
        "talk": plan.talk,
        "text": plan.text,
        "is_unlimited_plan": plan.is_unlimited_plan,
        "is_familyplan": plan.is_familyplan,
        "is_prepaid_postpaid": plan.is_prepaid_postpaid,
        "plan_expiry_days": plan.plan_expiry_days,
        "plan_expiry_type": plan.plan_expiry_type,
        "carrier": plan.carrier,
        "minute_unlimited": plan.minute_unlimited as Any,
        "text_unlimited": plan.text_unlimited as Any,
        "data_unlimited": plan.data_unlimited as Any,
        "plan_discount_details": plan.plan_discount_details,
        "autopay_discount": plan.autopay_discount
      ]
      plansData.append(planDict)
    }
    
    // Save to Firestore
    let planData: [String: Any] = [
      "zipCode": zipCode,
      "enrollmentType": enrollmentType,
      "isFamilyPlan": isFamilyPlan,
      "plans": plansData,
      "lastUpdated": FieldValue.serverTimestamp()
    ]
    
    db.collection("plans").document(documentId).setData(planData) { error in
      if let error = error {
        print("❌ Error saving plans to Firestore: \(error.localizedDescription)")
        completion(false, error)
      } else {
        print("✅ Plans saved to Firestore for zip code: \(zipCode)")
        completion(true, nil)
      }
    }
  }
  
  /// Retrieve plans from Firestore for a given zip code, enrollment type, and family plan status
  func getPlans(
    zipCode: String,
    enrollmentType: String,
    isFamilyPlan: String,
    completion: @escaping ([Plan]?, Error?) -> Void
  ) {
    let documentId = "\(zipCode)_\(enrollmentType)_\(isFamilyPlan)"
    
    db.collection("plans").document(documentId).getDocument { snapshot, error in
      if let error = error {
        print("❌ Error getting plans from Firestore: \(error.localizedDescription)")
        completion(nil, error)
        return
      }
      
      guard let data = snapshot?.data(),
            let plansArray = data["plans"] as? [[String: Any]] else {
        print("⚠️ No plans found in Firestore for zip code: \(zipCode)")
        completion(nil, nil)
        return
      }
      
      // Convert dictionary array back to Plan objects
      var plans: [Plan] = []
      for planDict in plansArray {
        // Convert to JSON data first, then decode
        if let jsonData = try? JSONSerialization.data(withJSONObject: planDict),
           let plan = try? JSONDecoder().decode(Plan.self, from: jsonData) {
          plans.append(plan)
        }
      }
      
      if plans.isEmpty {
        print("⚠️ No valid plans found in Firestore for zip code: \(zipCode)")
        completion(nil, nil)
      } else {
        print("✅ Retrieved \(plans.count) plans from Firestore for zip code: \(zipCode)")
        completion(plans, nil)
      }
    }
  }
  
  /// Clear plans cache for a specific zip code (optional - for cleanup)
  func clearPlansCache(
    zipCode: String,
    enrollmentType: String,
    isFamilyPlan: String,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    let documentId = "\(zipCode)_\(enrollmentType)_\(isFamilyPlan)"
    
    db.collection("plans").document(documentId).delete { error in
      if let error = error {
        print("❌ Error clearing plans cache: \(error.localizedDescription)")
        completion(false, error)
      } else {
        print("✅ Plans cache cleared for zip code: \(zipCode)")
        completion(true, nil)
      }
    }
  }
  
  // Save enrollment_id to order
  func saveEnrollmentId(
    userId: String,
    orderId: String,
    enrollmentId: String,
    completion: @escaping (Bool, Error?) -> Void
  ) {
    print("💾 Saving enrollment_id: \(enrollmentId) to order: \(orderId)")
    
    let orderRef = db.collection("users").document(userId)
      .collection("orders").document(orderId)
    
    orderRef.setData([
      "enrollment_id": enrollmentId,
      "updatedAt": FieldValue.serverTimestamp()
    ], merge: true) { error in
      if let error = error {
        print("❌ Error saving enrollment_id: \(error.localizedDescription)")
        completion(false, error)
      } else {
        print("✅ Successfully saved enrollment_id to order")
        completion(true, nil)
      }
    }
  }
}

import FirebaseAuth
import FirebaseFirestore
import Foundation

class FirebaseOrderManager {
  static let shared = FirebaseOrderManager()
  private let db = Firestore.firestore()

  private init() {}

  // MARK: - Step Progress Helpers

  /// Save the user's progress for an order, updating currentStep and status.
  func saveStepProgress(
    userId: String,
    orderId: String,
    step: Int,
    data: [String: Any] = [:],
    completion: ((Result<Void, Error>) -> Void)? = nil
  ) {
    var payload: [String: Any] = data
    payload["userId"] = userId
    payload["currentStep"] = step
    // keep status "pending" to match existing model unless it's completed
    payload["status"] = payload["status"] ?? "pending"
    payload["updatedAt"] = FieldValue.serverTimestamp()

    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(payload, merge: true) { error in
        if let error = error {
          completion?(.failure(error))
        } else {
          completion?(.success(()))
        }
      }
  }

  /// Mark an order as completed
  func markOrderCompleted(
    userId: String, orderId: String, completion: ((Result<Void, Error>) -> Void)? = nil
  ) {
    let data: [String: Any] = [
      "status": "completed",
      "updatedAt": FieldValue.serverTimestamp(),
    ]

    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .setData(data, merge: true) { error in
        if let error = error {
          completion?(.failure(error))
        } else {
          completion?(.success(()))
        }
      }
  }

  /// Fetch the latest in-progress order (status pending) for a user to resume
  func fetchLatestIncompleteOrder(
    for userId: String,
    completion: @escaping (Result<(orderId: String, currentStep: Int), Error>) -> Void
  ) {
    db.collection("users").document(userId)
      .collection("orders")
      .whereField("status", isEqualTo: "pending")
      .order(by: "updatedAt", descending: true)
      .limit(to: 1)
      .getDocuments { snapshot, error in
        if let error = error {
          completion(.failure(error))
          return
        }
        guard let doc = snapshot?.documents.first else {
          completion(
            .failure(
              NSError(
                domain: "FirebaseOrderManager", code: 404,
                userInfo: [NSLocalizedDescriptionKey: "No in-progress order found"])))
          return
        }
        let data = doc.data()
        let step = data["currentStep"] as? Int ?? 1
        completion(.success((orderId: doc.documentID, currentStep: step)))
      }
  }

  func fetchUserOrders(completion: @escaping ([TrumpOrder]) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("DEBUG: Error in FirebaseOrderManager - No authenticated user")
      completion([])
      return
    }

    print("DEBUG: Fetching orders for userId: \(userId)")

    // Fix: Query the subcollection instead of root collection
    db.collection("users").document(userId).collection("orders")
      .order(by: "updatedAt", descending: true)
      .getDocuments { snapshot, error in
        if let error = error {
          print("DEBUG: Error fetching orders: \(error.localizedDescription)")
          completion([])
          return
        }

        let orders =
          snapshot?.documents.compactMap { doc -> TrumpOrder? in
            do {
              // Create TrumpOrder from document data
              let data = doc.data()

              // Map the document data to TrumpOrder properties
              guard let userId = data["userId"] as? String else { return nil }

              let order = TrumpOrder(
                id: doc.documentID,
                userId: userId,
                planName: data["planName"] as? String ?? "Trump Mobile Plan",
                amount: data["amount"] as? Double ?? 47.45,
                orderDate: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TrumpOrder.OrderStatus(rawValue: data["status"] as? String ?? "pending")
                  ?? .pending,
                billingCompleted: data["billingCompleted"] as? Bool ?? false,
                phoneNumber: data["selectedPhoneNumber"] as? String,
                simType: data["simType"] as? String ?? "Physical SIM",
                currentStep: data["currentStep"] as? Int
              )

              return order
            } catch {
              print("DEBUG: Error creating order from document: \(error)")
              return nil
            }
          } ?? []

        print("DEBUG: Successfully fetched \(orders.count) orders")
        completion(orders)
      }
  }

  func fetchCompletedOrders(completion: @escaping ([TrumpOrder]) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("DEBUG: Error in FirebaseOrderManager - No authenticated user")
      completion([])
      return
    }

    print("DEBUG: Fetching completed orders for userId: \(userId)")

    // Fix: Query the subcollection with status filter
    db.collection("users").document(userId).collection("orders")
      .whereField("status", isEqualTo: "completed")
      .order(by: "updatedAt", descending: true)
      .getDocuments { snapshot, error in
        if let error = error {
          print("DEBUG: Error fetching completed orders: \(error.localizedDescription)")
          completion([])
          return
        }

        let orders =
          snapshot?.documents.compactMap { doc -> TrumpOrder? in
            do {
              let data = doc.data()

              guard let userId = data["userId"] as? String else { return nil }

              let order = TrumpOrder(
                id: doc.documentID,
                userId: userId,
                planName: data["planName"] as? String ?? "Trump Mobile Plan",
                amount: data["amount"] as? Double ?? 47.45,
                orderDate: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TrumpOrder.OrderStatus(rawValue: data["status"] as? String ?? "pending")
                  ?? .pending,
                billingCompleted: data["billingCompleted"] as? Bool ?? false,
                phoneNumber: data["selectedPhoneNumber"] as? String,
                simType: data["simType"] as? String ?? "Physical SIM",
                currentStep: data["currentStep"] as? Int
              )

              return order
            } catch {
              print("DEBUG: Error creating completed order from document: \(error)")
              return nil
            }
          } ?? []

        print("DEBUG: Successfully fetched \(orders.count) completed orders")
        completion(orders)
      }
  }

  // Alternative method to fetch orders by multiple statuses
  func fetchOrdersByStatus(
    _ statuses: [TrumpOrder.OrderStatus], completion: @escaping ([TrumpOrder]) -> Void
  ) {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("DEBUG: Error in FirebaseOrderManager - No authenticated user")
      completion([])
      return
    }

    let statusStrings = statuses.map { $0.rawValue }

    // Fix: Query the subcollection with status filter
    db.collection("users").document(userId).collection("orders")
      .whereField("status", in: statusStrings)
      .order(by: "updatedAt", descending: true)
      .getDocuments { snapshot, error in
        if let error = error {
          print("DEBUG: Error fetching orders by status: \(error.localizedDescription)")
          completion([])
          return
        }

        let orders =
          snapshot?.documents.compactMap { doc -> TrumpOrder? in
            do {
              let data = doc.data()

              guard let userId = data["userId"] as? String else { return nil }

              let order = TrumpOrder(
                id: doc.documentID,
                userId: userId,
                planName: data["planName"] as? String ?? "Trump Mobile Plan",
                amount: data["amount"] as? Double ?? 47.45,
                orderDate: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                status: TrumpOrder.OrderStatus(rawValue: data["status"] as? String ?? "pending")
                  ?? .pending,
                billingCompleted: data["billingCompleted"] as? Bool ?? false,
                phoneNumber: data["selectedPhoneNumber"] as? String,
                simType: data["simType"] as? String ?? "Physical SIM",
                currentStep: data["currentStep"] as? Int
              )

              return order
            } catch {
              print("DEBUG: Error creating order from document: \(error)")
              return nil
            }
          } ?? []

        print("DEBUG: Successfully fetched \(orders.count) orders with specified statuses")
        completion(orders)
      }
  }

  func deleteOrder(orderId: String, completion: @escaping (Bool) -> Void) {
    print("DEBUG: FirebaseOrderManager.deleteOrder called with orderId: \(orderId)")

    guard let userId = Auth.auth().currentUser?.uid else {
      print("DEBUG: Error in FirebaseOrderManager - No authenticated user")
      completion(false)
      return
    }

    print("DEBUG: Found userId: \(userId), proceeding with order deletion")

    // Use the existing FirebaseManager to delete the order
    FirebaseManager.shared.deleteOrder(userId: userId, orderId: orderId) { success, error in
      if success {
        print("DEBUG: FirebaseOrderManager - Successfully deleted order \(orderId)")
      } else {
        print(
          "DEBUG: FirebaseOrderManager - Failed to delete order: \(error?.localizedDescription ?? "unknown error")"
        )
      }
      completion(success)
    }
  }

  // MARK: - Fetch a single order document

  /// Fetch a single order document for the current authenticated user.
  /// - Parameters:
  ///   - orderId: The order document ID under users/{uid}/orders/{orderId}
  ///   - completion: Returns the raw document data on success
  func fetchOrderDocument(
    orderId: String,
    completion: @escaping (Result<[String: Any], Error>) -> Void
  ) {
    guard let userId = Auth.auth().currentUser?.uid else {
      completion(
        .failure(
          NSError(
            domain: "FirebaseOrderManager",
            code: 401,
            userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
      )
      return
    }

    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .getDocument { snapshot, error in
        if let error = error {
          completion(.failure(error))
          return
        }
        guard let data = snapshot?.data() else {
          completion(
            .failure(
              NSError(
                domain: "FirebaseOrderManager",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Order not found"]))
          )
          return
        }
        completion(.success(data))
      }
  }
}

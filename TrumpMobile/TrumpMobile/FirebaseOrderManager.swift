import Foundation
import FirebaseAuth

class FirebaseOrderManager {
    
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
                print("DEBUG: FirebaseOrderManager - Failed to delete order: \(error?.localizedDescription ?? "unknown error")")
            }
            completion(success)
        }
    }
}

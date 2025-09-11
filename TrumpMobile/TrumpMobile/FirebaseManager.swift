import Foundation
import Firebase
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    private let db = Firestore.firestore()
    
    // Save user registration data
    func saveUserRegistration(userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).setData(data) { error in
            completion(error == nil, error)
        }
    }
    
    // Update user registration data
    func updateUserRegistration(userId: String, data: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).updateData(data) { error in
            completion(error == nil, error)
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
}

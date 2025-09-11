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
        let userRef = db.collection("users").document(userId)
        
        // Check if document exists first
        userRef.getDocument { (document, error) in
            if let error = error {
                completion(false, error)
                return
            }
            
            if document?.exists == true {
                // Document exists, update it
                userRef.updateData(data) { error in
                    completion(error == nil, error)
                }
            } else {
                // Document doesn't exist, create it
                userRef.setData(data, merge: true) { error in
                    completion(error == nil, error)
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
    func saveContactInfo(userId: String, contactData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).collection("contactInfo").document("primary")
            .setData(contactData, merge: true) { error in
                completion(error == nil, error)
            }
    }
    
    // Save shipping address separately
    func saveShippingAddress(userId: String, addressData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).collection("shippingAddresses").document("primary")
            .setData(addressData, merge: true) { error in
                completion(error == nil, error)
            }
    }
    
    // Save billing address separately
    func saveBillingAddress(userId: String, addressData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        db.collection("users").document(userId).collection("billingAddresses").document("primary")
            .setData(addressData, merge: true) { error in
                completion(error == nil, error)
            }
    }
    
    // Get contact information
    func getContactInfo(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(userId).collection("contactInfo").document("primary")
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
    
    // Get shipping address
    func getShippingAddress(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(userId).collection("shippingAddresses").document("primary")
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
    
    // Get billing address
    func getBillingAddress(userId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        db.collection("users").document(userId).collection("billingAddresses").document("primary")
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
}

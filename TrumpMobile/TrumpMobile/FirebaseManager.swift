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
        print("📝 updateUserRegistration called for userId: \(userId)")
        print("📝 Data to update: \(data)")
        
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
                userRef.updateData(data) { error in
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
                userRef.setData(data, merge: true) { error in
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
    func saveContactInfo(userId: String, contactData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        print("📞 saveContactInfo called for userId: \(userId)")
        print("📞 contactData: \(contactData)")
        
        db.collection("users").document(userId).collection("contactInfo").document("primary")
            .setData(contactData, merge: true) { error in
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
    func saveShippingAddress(userId: String, addressData: [String: Any], completion: @escaping (Bool, Error?) -> Void) {
        print("📍 saveShippingAddress called for userId: \(userId)")
        print("📍 addressData: \(addressData)")
        
        db.collection("users").document(userId).collection("shippingAddresses").document("primary")
            .setData(addressData, merge: true) { error in
                if let error = error {
                    print("❌ Error saving shipping address: \(error.localizedDescription)")
                    completion(false, error)
                } else {
                    print("✅ Shipping address saved successfully")
                    completion(true, nil)
                }
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
        print("📱 getContactInfo called for userId: \(userId)")
        
        db.collection("users").document(userId).collection("contactInfo").document("primary")
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
        db.collection("users").document(userId).collection("contactInfo").document("primary").getDocument { snapshot, error in
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
        db.collection("users").document(userId).collection("shippingAddresses").document("primary").getDocument { snapshot, error in
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
}

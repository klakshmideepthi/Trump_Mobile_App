import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ContactInfoDetailViewModel: ObservableObject {
    // Reset all user-specific data (call on logout)
    func reset() {
        contactInfo = ContactInfoData()
        shippingAddress = ShippingAddressData()
        isLoading = false
        showError = false
        errorMessage = ""
    }
    @Published var contactInfo = ContactInfoData()
    @Published var shippingAddress = ShippingAddressData()
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let firebaseManager = FirebaseManager.shared
    
    func loadContactInfo() {
        guard let currentUser = Auth.auth().currentUser else {
            showError(message: "User not authenticated")
            return
        }
        
        let userId = currentUser.uid
        let userEmail = currentUser.email ?? ""
        
        isLoading = true
        
        // Use dispatch group to load both contact info and shipping address
        let dispatchGroup = DispatchGroup()
        var contactError: Error?
        var shippingError: Error?
        
        // Load contact information
        dispatchGroup.enter()
        firebaseManager.getContactInfo(userId: userId) { [weak self] data, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                contactError = error
                return
            }
            
            DispatchQueue.main.async {
                if let data = data {
                    self?.contactInfo = ContactInfoData(
                        firstName: data["firstName"] as? String ?? "",
                        lastName: data["lastName"] as? String ?? "",
                        email: data["email"] as? String ?? userEmail, // Use authenticated user's email as fallback
                        phoneNumber: data["phoneNumber"] as? String ?? ""
                    )
                } else {
                    // If no stored data, use the authenticated user's email
                    self?.contactInfo = ContactInfoData(
                        firstName: "",
                        lastName: "",
                        email: userEmail,
                        phoneNumber: ""
                    )
                }
            }
        }
        
        // Load shipping address
        dispatchGroup.enter()
        firebaseManager.getShippingAddress(userId: userId) { [weak self] data, error in
            defer { dispatchGroup.leave() }
            
            if let error = error {
                shippingError = error
                return
            }
            
            DispatchQueue.main.async {
                if let data = data {
                    self?.shippingAddress = ShippingAddressData(
                        street: data["street"] as? String ?? "",
                        aptNumber: data["aptNumber"] as? String ?? "",
                        city: data["city"] as? String ?? "",
                        state: data["state"] as? String ?? "",
                        zip: data["zip"] as? String ?? ""
                    )
                }
            }
        }
        
        // Handle completion
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
            
            // Check for errors
            if let contactError = contactError {
                self.showError(message: "Failed to load contact information: \(contactError.localizedDescription)")
            } else if let shippingError = shippingError {
                self.showError(message: "Failed to load shipping address: \(shippingError.localizedDescription)")
            }
        }
    }
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
}

struct ContactInfoData {
    var firstName: String = ""
    var lastName: String = ""
    var email: String = ""
    var phoneNumber: String = ""
}

struct ShippingAddressData {
    var street: String = ""
    var aptNumber: String = ""
    var city: String = ""
    var state: String = ""
    var zip: String = ""
}

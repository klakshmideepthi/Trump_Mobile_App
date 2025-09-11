import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

class UserRegistrationViewModel: ObservableObject {
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
    // Step 6
    @Published var creditCardNumber: String = ""
    @Published var billingDetails: String = ""
    @Published var address: String = ""
    @Published var country: String = "USA"
    @Published var deviceIsCompatible: Bool = false
    
    @Published var userId: String? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
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
        
        FirebaseManager.shared.updateUserRegistration(userId: userId, data: stepData) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                } else {
                    completion(success)
                }
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
                "accountType": self.accountType,
                "email": self.email,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            FirebaseManager.shared.saveUserRegistration(userId: user.uid, data: initialData) { success, error in
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
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
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
                    self.errorMessage = "Failed to sign in"
                    completion(false)
                }
                return
            }
            
            self.userId = user.uid
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
            completion(false)
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let group = DispatchGroup()
        
        // Load main user data
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
                    // Update properties from main user document
                    self.accountType = data["accountType"] as? String ?? ""
                    self.email = data["email"] as? String ?? ""
                    self.firstName = data["firstName"] as? String ?? ""
                    self.lastName = data["lastName"] as? String ?? ""
                    self.phoneNumber = data["phoneNumber"] as? String ?? ""
                    self.deviceBrand = data["deviceBrand"] as? String ?? ""
                    self.deviceModel = data["deviceModel"] as? String ?? ""
                    self.imei = data["imei"] as? String ?? ""
                    self.simType = data["simType"] as? String ?? ""
                    self.numberType = data["numberType"] as? String ?? ""
                    self.selectedPhoneNumber = data["selectedPhoneNumber"] as? String ?? ""
                    self.creditCardNumber = data["creditCardNumber"] as? String ?? ""
                    self.billingDetails = data["billingDetails"] as? String ?? ""
                    self.address = data["address"] as? String ?? ""
                    self.country = data["country"] as? String ?? "USA"
                    self.deviceIsCompatible = data["deviceIsCompatible"] as? Bool ?? false
                }
            }
        }
        
        // Load contact info
        group.enter()
        FirebaseManager.shared.getContactInfo(userId: userId) { [weak self] data, error in
            defer { group.leave() }
            guard let self = self, let data = data else { return }
            
            DispatchQueue.main.async {
                // Update contact properties
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
                // Update address properties
                self.street = data["street"] as? String ?? self.street
                self.aptNumber = data["aptNumber"] as? String ?? self.aptNumber
                self.zip = data["zip"] as? String ?? self.zip
                self.city = data["city"] as? String ?? self.city
                self.state = data["state"] as? String ?? self.state
            }
        }
        
        // Load billing address
        group.enter()
        FirebaseManager.shared.getBillingAddress(userId: userId) { [weak self] data, error in
            defer { group.leave() }
            guard let self = self, let data = data else { return }
            
            DispatchQueue.main.async {
                // Update billing address properties
                self.address = data["address"] as? String ?? self.address
                self.country = data["country"] as? String ?? self.country
            }
        }
        
        // When all data is loaded
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            self.isLoading = false
            completion(true)
        }
    }
    
    // Save contact information
    func saveContactInfo(completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            completion(false)
            return
        }
        
        isLoading = true
        
        // Create contact data
        let contactData: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "phoneNumber": phoneNumber
        ]
        
        // Create shipping address data
        let shippingAddressData: [String: Any] = [
            "street": street,
            "aptNumber": aptNumber,
            "zip": zip,
            "city": city,
            "state": state,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // First save contact info to user document
        saveCurrentStepData(stepData: contactData) { [weak self] success in
            guard let self = self, success else {
                self?.isLoading = false
                completion(false)
                return
            }
            
            // Then save contact info to subcollection
            FirebaseManager.shared.saveContactInfo(userId: userId, contactData: contactData) { success, error in
                if !success {
                    self.errorMessage = error?.localizedDescription
                    self.isLoading = false
                    completion(false)
                    return
                }
                
                // Finally save shipping address
                FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: shippingAddressData) { success, error in
                    self.isLoading = false
                    if !success {
                        self.errorMessage = error?.localizedDescription
                        completion(false)
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    
    // Save device information
    func saveDeviceInfo(completion: @escaping (Bool) -> Void) {
        let deviceData: [String: Any] = [
            "deviceBrand": deviceBrand,
            "deviceModel": deviceModel,
            "imei": imei,
            "deviceIsCompatible": deviceIsCompatible
        ]
        
        saveCurrentStepData(stepData: deviceData, completion: completion)
    }
    
    // Save SIM selection
    func saveSimSelection(completion: @escaping (Bool) -> Void) {
        let simData: [String: Any] = [
            "simType": simType
        ]
        
        saveCurrentStepData(stepData: simData, completion: completion)
    }
    
    // Save number selection
    func saveNumberSelection(completion: @escaping (Bool) -> Void) {
        let numberData: [String: Any] = [
            "numberType": numberType,
            "selectedPhoneNumber": selectedPhoneNumber
        ]
        
        saveCurrentStepData(stepData: numberData, completion: completion)
    }
    
    // Save billing information
    func saveBillingInfo(completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            errorMessage = "User ID not available"
            completion(false)
            return
        }
        
        isLoading = true
        
        // Create billing data for main user document
        let billingData: [String: Any] = [
            "creditCardNumber": creditCardNumber,
            "billingDetails": billingDetails
        ]
        
        // Create billing address data for subcollection
        let billingAddressData: [String: Any] = [
            "address": address,
            "country": country,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        // First save to main user document
        saveCurrentStepData(stepData: billingData) { [weak self] success in
            guard let self = self, success else {
                self?.isLoading = false
                completion(false)
                return
            }
            
            // Then save billing address to subcollection
            FirebaseManager.shared.saveBillingAddress(userId: userId, addressData: billingAddressData) { success, error in
                self.isLoading = false
                if !success {
                    self.errorMessage = error?.localizedDescription
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    // Save final order
    func completeOrder(completion: @escaping (Bool) -> Void) {
        let orderData: [String: Any] = [
            "orderCompleted": true,
            "orderCompletionDate": FieldValue.serverTimestamp()
        ]
        
        saveCurrentStepData(stepData: orderData, completion: completion)
    }
}

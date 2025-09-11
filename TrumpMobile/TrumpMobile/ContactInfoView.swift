import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onCancel: (() -> Void)? = nil
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        FixedBottomNavigationView(
            currentStep: 1, 
            backAction: {}, 
            nextAction: {
                print("📲 Next button tapped in ContactInfoView")
                // This is the critical fix - make sure we save before continuing
                if let userId = viewModel.userId ?? Auth.auth().currentUser?.uid {
                    print("👤 Using userId: \(userId)")
                    viewModel.userId = userId  // Ensure userId is set
                    
                    // Save contact info before continuing
                    viewModel.saveContactInfo { success in
                        if success {
                            print("✅ Contact info saved successfully, calling onNext")
                            onNext()
                        } else {
                            print("❌ Failed to save contact info: \(viewModel.errorMessage ?? "Unknown error")")
                            errorMessage = viewModel.errorMessage ?? "Failed to save contact information"
                        }
                    }
                } else {
                    print("❌ No userId available")
                    errorMessage = "User ID not available. Please log in again."
                }
            }, 
            isNextDisabled: viewModel.firstName.isEmpty || viewModel.lastName.isEmpty || viewModel.phoneNumber.isEmpty || isLoading,
            cancelAction: onCancel,
            disableBackButton: true,
            disableCancelButton: false,
            nextButtonText: "Next Step"
        ) {
            VStack(alignment: .center, spacing: 20) {
                // Step indicator is now provided by FixedBottomNavigationView
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding(.top)
                }
                
                // Always show status message if available
                if let message = errorMessage {
                    Text(message)
                        .foregroundColor(message.contains("success") ? .green : .red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Form fields
                if !isLoading {
                    // Contact Information Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("CONTACT INFORMATION")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.trumpText)
                    
                        // Input fields with improved styling
                        TextField("First Name", text: $viewModel.firstName)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        
                        TextField("Last Name", text: $viewModel.lastName)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        TextField("Phone Number", text: $viewModel.phoneNumber)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .keyboardType(.phonePad)
                    }
                    .padding(.horizontal)
            
                    // Customer Address Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("SHIPPING ADDRESS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.trumpText)
                            .padding(.top, 10)
                        
                        TextField("Street Address", text: $viewModel.street)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        TextField("Apt, Suite, etc. (optional)", text: $viewModel.aptNumber)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        TextField("City", text: $viewModel.city)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        HStack(spacing: 15) {
                            TextField("State", text: $viewModel.state)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            
                            TextField("Zip Code", text: $viewModel.zip)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                                .keyboardType(.numberPad)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 30)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadUserData()
        }
    }
    
    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        // If we have an orderId, try to load data from the order
        if let orderId = viewModel.orderId {
            print("🔄 Loading data from order: \(orderId)")
            
            // Load contact info and shipping address directly from the order document
            dispatchGroup.enter()
            db.collection("users").document(user.uid)
                .collection("orders").document(orderId).getDocument { document, error in
                    defer { dispatchGroup.leave() }
                    
                    if let error = error {
                        print("❌ Error loading order data: \(error.localizedDescription)")
                        return
                    }
                    
                    if let document = document, document.exists, let data = document.data() {
                        print("✅ Found order data")
                        DispatchQueue.main.async {
                            // Update with order's contact info
                            self.viewModel.firstName = data["firstName"] as? String ?? self.viewModel.firstName
                            self.viewModel.lastName = data["lastName"] as? String ?? self.viewModel.lastName
                            self.viewModel.phoneNumber = data["phoneNumber"] as? String ?? self.viewModel.phoneNumber
                            
                            // Update with order's shipping address
                            self.viewModel.street = data["street"] as? String ?? self.viewModel.street
                            self.viewModel.aptNumber = data["aptNumber"] as? String ?? self.viewModel.aptNumber
                            self.viewModel.city = data["city"] as? String ?? self.viewModel.city
                            self.viewModel.state = data["state"] as? String ?? self.viewModel.state
                            self.viewModel.zip = data["zip"] as? String ?? self.viewModel.zip
                        }
                    } else {
                        print("⚠️ No order data found")
                    }
                }
        } else {
            // If no orderId, load from user's main document and subcollections
            // Load main user data
            dispatchGroup.enter()
            db.collection("users").document(user.uid).getDocument { document, error in
                defer { dispatchGroup.leave() }
                
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Failed to load your information: \(error.localizedDescription)"
                    }
                    return
                }
                
                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        // Auto-fill with main document data
                        self.viewModel.firstName = data["firstName"] as? String ?? self.viewModel.firstName
                        self.viewModel.lastName = data["lastName"] as? String ?? self.viewModel.lastName
                        self.viewModel.phoneNumber = data["phoneNumber"] as? String ?? self.viewModel.phoneNumber
                        self.viewModel.street = data["street"] as? String ?? self.viewModel.street
                        self.viewModel.aptNumber = data["aptNumber"] as? String ?? self.viewModel.aptNumber
                        self.viewModel.city = data["city"] as? String ?? self.viewModel.city
                        self.viewModel.state = data["state"] as? String ?? self.viewModel.state
                        self.viewModel.zip = data["zip"] as? String ?? self.viewModel.zip
                    }
                }
            }
            
            // Load contact info from subcollection
            dispatchGroup.enter()
            db.collection("users").document(user.uid).collection("contactInfo").document("primary").getDocument { document, error in
                defer { dispatchGroup.leave() }
                
                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        // Update with more specific contact info
                        self.viewModel.firstName = data["firstName"] as? String ?? self.viewModel.firstName
                        self.viewModel.lastName = data["lastName"] as? String ?? self.viewModel.lastName
                        self.viewModel.phoneNumber = data["phoneNumber"] as? String ?? self.viewModel.phoneNumber
                    }
                }
            }
            
            // Load shipping address from subcollection
            dispatchGroup.enter()
            db.collection("users").document(user.uid).collection("shippingAddress").document("primary").getDocument { document, error in
                defer { dispatchGroup.leave() }
                
                if let document = document, document.exists, let data = document.data() {
                    DispatchQueue.main.async {
                        // Update with shipping address info
                        self.viewModel.street = data["street"] as? String ?? self.viewModel.street
                        self.viewModel.aptNumber = data["aptNumber"] as? String ?? self.viewModel.aptNumber
                        self.viewModel.city = data["city"] as? String ?? self.viewModel.city
                        self.viewModel.state = data["state"] as? String ?? self.viewModel.state
                        self.viewModel.zip = data["zip"] as? String ?? self.viewModel.zip
                    }
                }
            }
        }
        
        // Once all data loading attempts are completed
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false
        }
    }
}

struct ContactInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {}, onCancel: {})
    }
}
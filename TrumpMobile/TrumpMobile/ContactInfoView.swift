import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        FixedBottomNavigationView(
            currentStep: 1, 
            backAction: {}, 
            nextAction: onNext, 
            isNextDisabled: viewModel.firstName.isEmpty || viewModel.lastName.isEmpty || viewModel.phoneNumber.isEmpty || isLoading
        ) {
            ScrollView {
                VStack(alignment: .center, spacing: 20) {
                    // Step Indicator - first step, so no back button
                    StepIndicator(currentStep: 1, showBackButton: false)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                            .padding()
                    } else if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                    } else {
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
                .padding()
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationBarHidden(true)
        .onAppear {
            loadUserData()
        }
    }
    
    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { document, error in
            isLoading = false
            
            if let error = error {
                errorMessage = "Failed to load your information: \(error.localizedDescription)"
                return
            }
            
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    // Auto-fill with existing data
                    viewModel.firstName = data["firstName"] as? String ?? ""
                    viewModel.lastName = data["lastName"] as? String ?? ""
                    viewModel.phoneNumber = data["phoneNumber"] as? String ?? ""
                    viewModel.street = data["street"] as? String ?? ""
                    viewModel.aptNumber = data["aptNumber"] as? String ?? ""
                    viewModel.city = data["city"] as? String ?? ""
                    viewModel.state = data["state"] as? String ?? ""
                    viewModel.zip = data["zip"] as? String ?? ""
                }
            }
            // If no document exists or data is incomplete, fields will remain empty
        }
    }
}

struct ContactInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {})
    }
}
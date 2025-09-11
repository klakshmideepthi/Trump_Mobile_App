import SwiftUI
import Firebase

struct CreateAccountView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Step 1: Create Account").font(.title)
            Picker("Sign up with", selection: $viewModel.accountType) {
                Text("Email").tag("Email")
                Text("Google").tag("Google")
                Text("Apple").tag("Apple")
            }
            .pickerStyle(SegmentedPickerStyle())
            
            if viewModel.accountType == "Email" || viewModel.accountType.isEmpty {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Button("Next Step") {
                if viewModel.password != viewModel.confirmPassword {
                    alertMessage = "Passwords do not match"
                    showingAlert = true
                } else {
                    onNext()
                }
            }
            .disabled(viewModel.accountType.isEmpty || 
                     (viewModel.accountType == "Email" && 
                      (viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.confirmPassword.isEmpty)))
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }
}

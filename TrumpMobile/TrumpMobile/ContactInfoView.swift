import SwiftUI

struct ContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .padding(.leading)
                Spacer()
            }
            Text("Step 2: Contact Information").font(.title2)
            TextField("First Name", text: $viewModel.firstName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Last Name", text: $viewModel.lastName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Phone Number", text: $viewModel.phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.phonePad)
            
            Text("Customer Address").font(.headline)
            TextField("Street/Area", text: $viewModel.street)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Apt Number", text: $viewModel.aptNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Zip", text: $viewModel.zip)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            TextField("City", text: $viewModel.city)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("State", text: $viewModel.state)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Button("Next Step") {
                onNext()
            }
            .disabled(viewModel.firstName.isEmpty || viewModel.lastName.isEmpty || viewModel.phoneNumber.isEmpty)
        }
    }
}

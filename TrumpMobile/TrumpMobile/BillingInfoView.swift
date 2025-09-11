import SwiftUI

struct BillingInfoView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.leading)
                }
                Spacer()
            }
            Text("Step 6: Billing Information").font(.title2)
            TextField("Credit Card Number", text: $viewModel.creditCardNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            TextField("Expiration Date (MM/YY)", text: $viewModel.billingDetails)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
            
            TextField("Billing Address", text: $viewModel.address)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            Picker("Country", selection: $viewModel.country) {
                Text("USA").tag("USA")
                Text("Canada").tag("Canada")
                Text("Mexico").tag("Mexico")
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical)
            
            Button("Complete Order") {
                onNext()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(viewModel.creditCardNumber.isEmpty || viewModel.billingDetails.isEmpty)
        }
    }
}

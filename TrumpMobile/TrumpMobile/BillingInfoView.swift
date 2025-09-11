import SwiftUI

struct BillingInfoView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        FixedBottomNavigationView(
            currentStep: 5,
            backAction: {
                if let onBack = onBack {
                    onBack()
                }
            },
            nextAction: {
                // Save billing info to orders collection
                viewModel.saveBillingInfo { success in
                    if success {
                        // Continue to next step only if save was successful
                        onNext()
                    } else {
                        print("Failed to save billing information")
                    }
                }
            },
            isNextDisabled: viewModel.creditCardNumber.isEmpty || viewModel.billingDetails.isEmpty,
            cancelAction: onCancel,
            nextButtonText: "Complete Order"
        ) {
            VStack(spacing: 16) {
                // Step indicator is now provided by FixedBottomNavigationView
                
                Text("Payment Information")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                
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
                .padding(.vertical, 8)
                
                Spacer()
            }
    }}
}

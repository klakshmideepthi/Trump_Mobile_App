import SwiftUI

struct BillingInfoView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        FixedBottomNavigationView(
            currentStep: 5,
            backAction: {
                if let onBack = onBack {
                    onBack()
                }
            },
            nextAction: onNext,
            isNextDisabled: viewModel.creditCardNumber.isEmpty || viewModel.billingDetails.isEmpty
        ) {
            VStack(spacing: 16) {
                // Step Indicator
                StepIndicator(currentStep: 5)
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
            
            Spacer(minLength: 50)
        }
        .padding()
    }}
}

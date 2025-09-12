import SwiftUI

struct OrderCompletionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onBack: (() -> Void)? = nil
    var onGoToHome: (() -> Void)? = nil
    @State private var orderCompleted = false
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        StepNavigationContainer(
            currentStep: 6,
            nextButtonText: "Go To Home",
            nextButtonDisabled: false,  // Button should always be active
            nextButtonAction: { 
                // Navigate back to home/start order view
                if let onGoToHome = onGoToHome {
                    onGoToHome()
                } else {
                    // If no specific handler provided, try to dismiss to the root view
                    presentationMode.wrappedValue.dismiss()
                }
            },
            backButtonAction: { if let onBack = onBack { onBack() } },
            cancelAction: onGoToHome,  // Enable cancel button to go to home
            disableBackButton: false,
            disableCancelButton: false  // Enable cancel button
        ) {
            VStack(spacing: 16) {
                Text("Thank you for joining TrumpMobile!")
                    .font(.title)
                    .multilineTextAlignment(.center)
                
                Text("Order Complete")
                    .font(.headline)
                
                Text("Broadband Facts: ...")
                
                // Show summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Order Summary")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text("Name: \(viewModel.firstName) \(viewModel.lastName)")
                    Text("Phone: \(viewModel.phoneNumber)")
                    Text("Selected Number: \(viewModel.selectedPhoneNumber)")
                    Text("SIM Type: \(viewModel.simType)")
                }
                .padding(12)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 2)
                
                Spacer()
            }
        }
        .onAppear {
            // Save final order data when view appears
            if !orderCompleted {
                viewModel.completeOrder { success in
                    orderCompleted = success
                    if !success {
                        showingError = true
                    }
                    // We don't disable the button regardless of success/failure
                }
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Failed to complete order"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

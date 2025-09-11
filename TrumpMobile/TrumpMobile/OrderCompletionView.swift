import SwiftUI

struct OrderCompletionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onBack: (() -> Void)? = nil
    @State private var orderCompleted = false
    @State private var showingError = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Step Indicator
            StepIndicator(currentStep: 5, showBackButton: false)
            Text("Step 7: Thank you for joining TrumpMobile!").font(.title)
            Text("Order Complete").font(.headline)
            Text("Broadband Facts: ...")
            
            // Show summary
            VStack(alignment: .leading, spacing: 10) {
                Text("Order Summary").font(.headline)
                Text("Name: \(viewModel.firstName) \(viewModel.lastName)")
                Text("Phone: \(viewModel.phoneNumber)")
                Text("Selected Number: \(viewModel.selectedPhoneNumber)")
                Text("SIM Type: \(viewModel.simType)")
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal)
            
            Spacer()
            
            Button("Complete Registration") {
                viewModel.completeOrder { success in
                    if success {
                        orderCompleted = true
                    } else {
                        showingError = true
                    }
                }
            }
            .padding()
            .background(Color(.systemBlue))
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(orderCompleted)
        }
        .onAppear {
            // Save final order data when view appears
            if !orderCompleted {
                viewModel.completeOrder { success in
                    orderCompleted = success
                    showingError = !success
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
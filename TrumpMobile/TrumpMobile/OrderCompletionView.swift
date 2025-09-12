import SwiftUI

struct OrderCompletionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onBack: (() -> Void)? = nil
    var onGoToHome: (() -> Void)? = nil
    @State private var orderCompleted = false
    @State private var showingError = false
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Generate a mock tracking ID (in real app, this would come from the API)
    private var trackingID: String {
        return "TM\(String(format: "%06d", Int.random(in: 100000...999999)))"
    }
    
    var body: some View {
        StepNavigationContainer(
            currentStep: 6,
            nextButtonText: "Go To Home",
            nextButtonDisabled: false,
            nextButtonAction: { 
                if let onGoToHome = onGoToHome {
                    onGoToHome()
                } else {
                    presentationMode.wrappedValue.dismiss()
                }
            },
            backButtonAction: { if let onBack = onBack { onBack() } },
            cancelAction: onGoToHome,
            disableBackButton: false,
            disableCancelButton: false
        ) {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Icon
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    // Thank you message
                    VStack(spacing: 8) {
                        Text("Thank you for joining TrumpMobile!")
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.primary)
                        
                        Text("Order Complete")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Mail notification
                    VStack(spacing: 12) {
                        Text("📧 Order Confirmation")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("We will be shortly mailing you your order details and activation instructions.")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                        
                        // Tracking ID
                        VStack(spacing: 8) {
                            Text("Tracking ID")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                            
                            Text(trackingID)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.blue.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Order Summary
                    VStack(spacing: 16) {
                        Text("Order Summary")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            OrderDetailRow(label: "Name", value: "\(viewModel.firstName) \(viewModel.lastName)")
                            OrderDetailRow(label: "Phone", value: viewModel.phoneNumber)
                            OrderDetailRow(label: "SIM Type", value: viewModel.simType)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                                .shadow(
                                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.1),
                                    radius: 8,
                                    x: 0,
                                    y: 2
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    colorScheme == .dark ? Color(.systemGray4) : Color(.systemGray5),
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            if !orderCompleted {
                viewModel.completeOrder { success in
                    orderCompleted = success
                    if !success {
                        showingError = true
                    }
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

// Helper view for order detail rows
struct OrderDetailRow: View {
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

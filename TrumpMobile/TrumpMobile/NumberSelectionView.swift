import SwiftUI

struct NumberSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var showNavigation: Bool = true  // New parameter to control navigation display
    
    var body: some View {
        let contentView = VStack(spacing: 24) {
            // Header section matching the screenshot
            VStack(spacing: 16) {
                Text("TRANSFER YOUR EXISTING NUMBER OR CHOOSE A NEW NUMBER")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 8)
            
            // Button section with styling similar to SimSelectionView
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.numberType = "Existing"
                }) {
                    Text("Transfer Your Existing Number")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            viewModel.numberType == "Existing" ?
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.clear, Color.clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        )
                        .foregroundColor(viewModel.numberType == "Existing" ? .white : .primary)
                }
                
                Button(action: {
                    viewModel.numberType = "New"
                }) {
                    Text("Choose a New Number")
                        .font(.system(size: 18, weight: .medium))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 2
                                )
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            viewModel.numberType == "New" ?
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ) :
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color.clear, Color.clear]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        )
                        .foregroundColor(viewModel.numberType == "New" ? .white : .primary)
                }
            }
            .padding(.horizontal, 16)
            
            // Conditional content based on selection
            if viewModel.numberType == "Existing" {
                // Explanatory text similar to screenshot
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .bold))
                            .padding(.top, 2)
                        
                        Text("If you prefer to transfer your existing number to us, supply us with the Account Number, Account Name, Account Address, and most importantly a Transfer PIN or password. Without a correct PIN/Password, your existing carrier will NOT release your number to us. You can usually get the Transfer PIN by calling your carrier or obtain from their app. So please have such information ready before going onto the 'Next' step.")
                            .font(.system(size: 15))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter your existing number:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.top, 6)
                        
                    TextField("(000) 000-0000", text: $viewModel.selectedPhoneNumber)
                        .font(.system(size: 16))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(.systemGray3), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                )
                        )
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        
        // Return either wrapped in navigation container or just the content
        if showNavigation {
            return AnyView(
                StepNavigationContainer(
                    currentStep: 4,
                    totalSteps: 6,
                    nextButtonText: "Next Step",
                    nextButtonDisabled: viewModel.numberType.isEmpty || 
                                  (viewModel.numberType == "Existing" && viewModel.selectedPhoneNumber.isEmpty),
                    nextButtonAction: {
                        // Save number selection to orders collection
                        viewModel.saveNumberSelection { success in
                            if success {
                                // Continue to next step only if save was successful
                                onNext()
                            } else {
                                print("Failed to save number selection")
                            }
                        }
                    },
                    backButtonAction: {
                        if let onBack = onBack {
                            onBack()
                        }
                    },
                    cancelAction: onCancel
                ) {
                    contentView
                }
            )
        } else {
            return AnyView(contentView)
        }
    }
}
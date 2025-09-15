import SwiftUI

struct SimSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var showNavigation: Bool = true  // New parameter to control navigation display
    
    var body: some View {
        let contentView = VStack(spacing: 24) {
            // Header section with better spacing
            VStack(spacing: 16) {
                Text("CONGRATULATIONS!")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("YOUR PHONE IS COMPATIBLE\nWITH OUR NETWORK.")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.top, 8)
            
            // Button section with vertical layout for better mobile experience
            VStack(spacing: 12) {
                Button(action: {
                    viewModel.simType = "eSIM"
                }) {
                    Text("I want eSIM")
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
                                            viewModel.simType == "eSIM" ?
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
                        .foregroundColor(viewModel.simType == "eSIM" ? .white : .primary)
                }
                
                Button(action: {
                    viewModel.simType = "Physical"
                }) {
                    Text("I want Physical SIM card")
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
                                            viewModel.simType == "Physical" ?
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
                        .foregroundColor(viewModel.simType == "Physical" ? .white : .primary)
                }
            }
            .padding(.horizontal, 16)
            
            // Explanatory text with better formatting
            VStack(alignment: .leading, spacing: 12) {
                ForEach([
                    "eSIM is a new method to deliver SIM cards onto phones electronically. Upon order completion, you'll see a QR code on-screen, via order confirmation emails and from within your Account Dashboard. Instead of having to wait for the physical SIM to arrive in the mail, just scanning it with the camera of your phone will download the eSIM onto it and be used with the Trump Mobile's service immediately.",
                    "Certain older phones can't take eSIMS and in these cases, we mail a physical SIM kit out the day after the order is received via First Class USPS Postal Mail.",
                    "Certain phones can take both eSIMs and physical SIMs, then it'll be up to you to choose which format to get with eSIM being the prefer method as delivery is instantaneous."
                ], id: \.self) { text in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundColor(.orange)
                            .font(.system(size: 16, weight: .bold))
                            .padding(.top, 2)
                        
                        Text(text)
                            .font(.system(size: 15))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            
            Spacer()
        }
        
        // Return either wrapped in navigation container or just the content
        if showNavigation {
            return AnyView(
                StepNavigationContainer(
                    currentStep: 3,
                    totalSteps: 6,
                    nextButtonText: "Next Step",
                    nextButtonDisabled: viewModel.simType.isEmpty,
                    nextButtonAction: {
                        // Save SIM selection to orders collection
                        viewModel.saveSimSelection { success in
                            if success {
                                // Continue to next step only if save was successful
                                onNext()
                            } else {
                                print("Failed to save SIM selection")
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

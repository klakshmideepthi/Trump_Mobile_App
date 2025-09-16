import SwiftUI

struct PortingView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var showNavigation: Bool = true
    
    @State private var showCarrierDropdown = false
    
    // Predefined carrier options
    private let carrierOptions = [
        "Verizon",
        "AT&T", 
        "T-Mobile",
        "Sprint",
        "Other"
    ]
    
    var body: some View {
        let contentView = VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    portInSection
                }
                .padding()
            }
            
            Spacer()
        }
        .background(Color.adaptiveBackground)
        .onTapGesture {
            if showCarrierDropdown {
                showCarrierDropdown = false
            }
        }
        
        // Return either wrapped in navigation container or just the content
        if showNavigation {
            return AnyView(
                StepNavigationContainer(
                    currentStep: 6,
                    totalSteps: 6,
                    nextButtonText: "Continue to SIM Setup",
                    nextButtonDisabled: !isPortInFormValid,
                    nextButtonAction: {
                        savePortInDataAndContinue()
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
    
    private var portInSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Transfer Your Existing Number")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.adaptiveText)
                
                Text("Please provide the following information from your current carrier:")
                    .font(.subheadline)
                    .foregroundColor(Color.adaptiveSecondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                CustomTextField(
                    title: "Phone Number to Transfer",
                    placeholder: "(555) 123-4567",
                    text: $viewModel.selectedPhoneNumber
                )
                .keyboardType(.phonePad)
                
                CustomTextField(
                    title: "Account Holder Name",
                    placeholder: "Full name on account",
                    text: $viewModel.portInAccountHolderName
                )
                
                // Current Carrier dropdown
                VStack(alignment: .leading, spacing: 6) {
                    Text("Current Carrier")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.adaptiveText)
                    
                    Button(action: {
                        showCarrierDropdown.toggle()
                    }) {
                        HStack {
                            Text(viewModel.portInCurrentCarrier.isEmpty ? "Verizon, AT&T, T-Mobile, etc." : viewModel.portInCurrentCarrier)
                                .foregroundColor(viewModel.portInCurrentCarrier.isEmpty ? Color.adaptiveSecondaryText : Color.adaptiveText)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(Color.adaptiveSecondaryText)
                                .rotationEffect(.degrees(showCarrierDropdown ? 180 : 0))
                                .animation(.easeInOut(duration: 0.2), value: showCarrierDropdown)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.adaptiveSecondaryBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.adaptiveBorder, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if showCarrierDropdown {
                        VStack(spacing: 0) {
                            ForEach(carrierOptions, id: \.self) { carrier in
                                Button(action: {
                                    viewModel.portInCurrentCarrier = carrier
                                    showCarrierDropdown = false
                                }) {
                                    HStack {
                                        Text(carrier)
                                            .foregroundColor(Color.adaptiveText)
                                        Spacer()
                                        if viewModel.portInCurrentCarrier == carrier {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(Color.accentGold)
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(
                                        viewModel.portInCurrentCarrier == carrier ? 
                                        Color.accentGold.opacity(0.1) : Color.clear
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                if carrier != carrierOptions.last {
                                    Divider()
                                        .background(Color.adaptiveBorder)
                                        .padding(.horizontal, 12)
                                }
                            }
                        }
                        .background(Color.adaptiveBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.adaptiveBorder, lineWidth: 1)
                        )
                        .shadow(color: Color.adaptiveText.opacity(0.1), radius: 5, x: 0, y: 2)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        .animation(.easeInOut(duration: 0.2), value: showCarrierDropdown)
                    }
                }
                
                CustomTextField(
                    title: "Account Number",
                    placeholder: "Account number from current carrier",
                    text: $viewModel.portInAccountNumber
                )
                
                CustomTextField(
                    title: "Account PIN/Password",
                    placeholder: "4-digit PIN or account password",
                    text: $viewModel.portInPin,
                    isSecure: true
                )
            }
            
            // Important information box
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(Color.accentGold2)
                    Text("Important Information:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.adaptiveText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Do NOT cancel your current service until the transfer is complete")
                        .foregroundColor(Color.adaptiveText)
                    Text("• Transfer typically takes 4-24 hours for wireless numbers")
                        .foregroundColor(Color.adaptiveText)
                    Text("• Keep your current phone active during the transfer process")
                        .foregroundColor(Color.adaptiveText)
                    Text("• Ensure all information matches exactly with your current carrier")
                        .foregroundColor(Color.adaptiveText)
                }
                .font(.caption)
            }
            .padding()
            .background(Color.accentGold2.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentGold2.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var isPortInFormValid: Bool {
        !viewModel.selectedPhoneNumber.isEmpty &&
        !viewModel.portInAccountHolderName.isEmpty &&
        !viewModel.portInCurrentCarrier.isEmpty &&
        !viewModel.portInAccountNumber.isEmpty &&
        !viewModel.portInPin.isEmpty
    }
    
    private func savePortInDataAndContinue() {
        // Save the port-in data to Firebase
        viewModel.saveNumberSelection { success in
            if success {
                onNext()
            } else {
                // Handle error - you might want to show an alert
                print("Failed to save port-in information")
            }
        }
    }
}

// Custom TextField component for consistent styling
struct CustomTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.adaptiveText)
            
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
            .foregroundColor(Color.adaptiveText)
        }
    }
}

#Preview {
    PortingView(
        viewModel: UserRegistrationViewModel(),
        onNext: {}
    )
}
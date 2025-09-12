import SwiftUI

struct NumberSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        StepNavigationContainer(
            currentStep: 4,
            totalSteps: 6,
            nextButtonText: "Next Step",
            nextButtonDisabled: viewModel.numberType.isEmpty || 
                          (viewModel.numberType == "New" && viewModel.selectedPhoneNumber.isEmpty) ||
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
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("Choose Your Number")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("You can either keep your existing number or select a new one")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.numberType = "Existing"
                }) {
                    Text("Existing")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.numberType == "Existing" ? Color.accentGold : Color.gray.opacity(0.2))
                        .foregroundColor(viewModel.numberType == "Existing" ? .white : .primary)
                        .cornerRadius(8)
                }
                Button(action: {
                    viewModel.numberType = "New"
                }) {
                    Text("New")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.numberType == "New" ? Color.accentGold : Color.gray.opacity(0.2))
                        .foregroundColor(viewModel.numberType == "New" ? .white : .primary)
                        .cornerRadius(8)
                }
            }
            if !viewModel.numberType.isEmpty {
                Text("You selected: \(viewModel.numberType)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            if viewModel.numberType == "New" {
                // Display some sample numbers to choose from
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a number:")
                        .font(.headline)
                        .padding(.top, 6)
                    
                    Button(action: {
                        viewModel.selectedPhoneNumber = "(202) 555-1234"
                    }) {
                        HStack {
                            Text("(202) 555-1234")
                                .font(.headline)
                                .foregroundColor(Color.accentGold)
                            Spacer()
                            if viewModel.selectedPhoneNumber == "(202) 555-1234" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.selectedPhoneNumber = "(202) 555-5678"
                    }) {
                        HStack {
                            Text("(202) 555-5678")
                                .font(.headline)
                                .foregroundColor(Color.accentGold)
                            Spacer()
                            if viewModel.selectedPhoneNumber == "(202) 555-5678" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
            } else if viewModel.numberType == "Existing" {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter your existing number:")
                        .font(.headline)
                        .padding(.top, 6)
                        
                    TextField("Enter your current phone number", text: $viewModel.selectedPhoneNumber)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                }
            }
            
            Spacer()
            }
        }
    }
}

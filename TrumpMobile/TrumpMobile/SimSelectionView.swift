import SwiftUI

struct SimSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
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
            VStack(spacing: 16) {
                VStack(spacing: 12) {
                    Text("Choose SIM Type")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            HStack(spacing: 16) {
                Button(action: {
                    viewModel.simType = "E-sim"
                }) {
                    Text("E-sim")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.simType == "E-sim" ? Color.accentGold : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    viewModel.simType = "Physical"
                }) {
                    Text("Physical")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(viewModel.simType == "Physical" ? Color.accentGold : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            if !viewModel.simType.isEmpty {
                Text("You selected: \(viewModel.simType)")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            
            Spacer()
            }
        }
    }
}

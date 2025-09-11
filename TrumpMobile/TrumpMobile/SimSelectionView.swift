import SwiftUI

struct SimSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        FixedBottomNavigationView(
            currentStep: 3,
            backAction: {
                if let onBack = onBack {
                    onBack()
                }
            },
            nextAction: onNext,
            isNextDisabled: viewModel.simType.isEmpty
        ) {
            VStack(spacing: 20) {
                // Step Indicator
                StepIndicator(currentStep: 3)
            HStack {
                Button(action: {
                    viewModel.simType = "E-sim"
                }) {
                    Text("E-sim")
                        .padding()
                        .background(viewModel.simType == "E-sim" ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    viewModel.simType = "Physical"
                }) {
                    Text("Physical")
                        .padding()
                        .background(viewModel.simType == "Physical" ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            if !viewModel.simType.isEmpty {
                Text("You selected: \(viewModel.simType)")
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
    }}
}

import SwiftUI

struct SimSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.leading)
                }
                Spacer()
            }
            Text("Step 4: Phone is compatible with our network").font(.title2)
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
            Button("Next Step") {
                onNext()
            }
            .disabled(viewModel.simType.isEmpty)
        }
    }
}

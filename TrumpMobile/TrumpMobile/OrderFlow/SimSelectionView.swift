import SwiftUI

struct SimSelectionView: View {
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onNext: () -> Void
  var onBack: (() -> Void)? = nil
  var onCancel: (() -> Void)? = nil
  var showNavigation: Bool = true  // New parameter to control navigation display

  var body: some View {
    let contentView = VStack(spacing: 24) {
      // Header section with unified styling
      OrderStepHeader(
        "Congratulations!",
        subtitle: "Your phone is compatible with our network."
      )

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
                      viewModel.simType == "eSIM"
                        ? LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                        : LinearGradient(
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
                      viewModel.simType == "Physical"
                        ? LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                        : LinearGradient(
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
        ForEach(
          [
            "eSIM is an easy way to activate service electronically. After you place your order, you’ll see a QR code on-screen, in your confirmation email, and in your Account Dashboard. Scan it with your phone’s camera to download the eSIM and start Telgoo5 Mobile service immediately.",
            "Some older phones don’t support eSIMs. In those cases, we’ll ship a physical SIM kit the next business day via USPS First Class Mail.",
            "Many phones support both eSIMs and physical SIMs. You can choose either, but eSIM is the preferred option for instant delivery.",
          ], id: \.self
        ) { text in
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
                if let userId = viewModel.userId, let orderId = viewModel.orderId {
                  FirebaseOrderManager.shared.saveStepProgress(
                    userId: userId, orderId: orderId, step: 3)
                }
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

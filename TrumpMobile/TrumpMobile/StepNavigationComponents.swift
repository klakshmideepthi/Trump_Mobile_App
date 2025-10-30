import SwiftUI

struct StepIndicatorText: View {
  let currentStep: Int
  let totalSteps: Int

  var body: some View {
  Text("Step \(currentStep) of \(totalSteps)")
    .font(.headline)
    .fontWeight(.bold)
    .foregroundColor(.white)
    .padding(.horizontal)   // adjust horizontal padding to taste
    .frame(height: 36)          // keep the capsule height fixed
    .background(
      Capsule().fill(
        LinearGradient(
          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
          startPoint: .leading,
          endPoint: .trailing
        )
      )
    )
    .fixedSize()                 // prevents stretching between Spacers
  }
}

struct StepNavigationContainer<Content: View>: View {
  let currentStep: Int
  let totalSteps: Int
  let nextButtonText: String
  let nextButtonAction: () -> Void
  let backButtonAction: () -> Void
  let content: Content
  let nextButtonDisabled: Bool
  let cancelAction: (() -> Void)?
  let disableBackButton: Bool
  let disableCancelButton: Bool
  @State private var showCancelConfirmation = false

  init(
    currentStep: Int,
    totalSteps: Int = 6,
    nextButtonText: String = "Next Step",
    nextButtonDisabled: Bool = false,
    nextButtonAction: @escaping () -> Void,
    backButtonAction: @escaping () -> Void,
    cancelAction: (() -> Void)? = nil,
    disableBackButton: Bool = false,
    disableCancelButton: Bool = false,
    @ViewBuilder content: () -> Content
  ) {
    self.currentStep = currentStep
    self.totalSteps = totalSteps
    self.nextButtonText = nextButtonText
    self.nextButtonDisabled = nextButtonDisabled
    self.nextButtonAction = nextButtonAction
    self.backButtonAction = backButtonAction
    self.cancelAction = cancelAction
    self.disableBackButton = disableBackButton
    self.disableCancelButton = disableCancelButton
    self.content = content()
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      VStack(spacing: 0) {
        AppHeader {
          // Back button on left
          Button(action: backButtonAction) {
            Image(systemName: "arrow.left")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(
                (currentStep == 1 || currentStep == 6 || disableBackButton)
                  ? Color.clear : Color.accentGold
              )
              .padding(.vertical, 8)
              .accessibilityLabel("Back")
              .accessibilityHint(currentStep == 1 ? "Back is unavailable on the first step" : "Go to the previous step")
          }
          .disabled(currentStep == 1 || currentStep == 6 || disableBackButton)

          Spacer()

          // Step indicator in center
          StepIndicatorText(currentStep: currentStep, totalSteps: totalSteps)
            .accessibilityLabel("Step \(currentStep) of \(totalSteps)")

          Spacer()

          // Cancel button on right - hidden in step 6, replaced with placeholder to keep center alignment
          if currentStep != 6 {
            Button(action: {
              print("DEBUG: Cancel button tapped in StepNavigationContainer")
              if cancelAction != nil {
                showCancelConfirmation = true
              } else {
                print("DEBUG: cancelAction is nil in StepNavigationContainer when tapped")
              }
            }) {
              Image(systemName: "xmark")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(disableCancelButton ? Color.clear : Color.accentGold)
                .padding(.vertical, 8)
                .accessibilityLabel("Cancel Order")
                .accessibilityHint("Cancel this order and return to Home")
            }
            .disabled(disableCancelButton)
          } else {
            // Placeholder to keep step indicator centered
            Image(systemName: "xmark")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(.clear)
              .padding(.vertical, 8)
          }
        }

        // Content area (flexible)
        ScrollView {
          content
            .padding(.horizontal, OrderStepLayout.horizontalPadding)
            .padding(.top, OrderStepLayout.verticalPadding)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 100)
        }
      }

      // Fixed navigation button at bottom (standardized)
      BottomActionBar {
        StepNavigationButton(
          currentStep: currentStep,
          totalSteps: totalSteps,
          buttonText: currentStep == 5 ? "Complete Order" : nextButtonText,
          isDisabled: nextButtonDisabled,
          action: nextButtonAction
        )
      }
    }
    .background(Color.adaptiveBackground)
    .alert(isPresented: $showCancelConfirmation) {
      Alert(
        title: Text("Cancel Order"),
        message: Text("Do you want to cancel the order?"),
        primaryButton: .destructive(Text("Yes, I want to cancel")) {
          print("DEBUG: Cancel button pressed in StepNavigationContainer")
          if let cancelAction = cancelAction {
            print("DEBUG: Executing cancelAction in StepNavigationContainer")
            cancelAction()
          } else {
            print("DEBUG: cancelAction is nil in StepNavigationContainer")
          }
        },
        secondaryButton: .cancel(Text("No, Keep Editing"))
      )
    }
    .navigationBarBackButtonHidden(true)
  }
}

struct StepNavigationButton: View {
  let currentStep: Int
  let totalSteps: Int
  let buttonText: String
  let isBackButton: Bool
  let action: () -> Void
  let isDisabled: Bool

  init(
    currentStep: Int,
    totalSteps: Int = 6,
    buttonText: String = "Next Step",
    isBackButton: Bool = false,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.currentStep = currentStep
    self.totalSteps = totalSteps
    self.buttonText = buttonText
    self.isBackButton = isBackButton
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack {
        // For back button, show chevron on left
        if isBackButton {
          Image(systemName: "chevron.left")
        }

        Text(buttonText)
          .fontWeight(.semibold)

        // For next/continue button, show chevron on right
        if !isBackButton {
          Image(systemName: "chevron.right")
        }
      }
      .padding(.vertical, 15)
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .background(
        Group {
          if isDisabled {
            Color.gray.opacity(0.6) // Slightly lighter when disabled for better contrast cues
          } else {
            LinearGradient(
              gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
              startPoint: .leading,
              endPoint: .trailing
            )
          }
        }
      )
      .cornerRadius(10)
    }
    .disabled(isDisabled || isSaving)
  }

  // Add a state to track saving
  @State private var isSaving: Bool = false
  // To use this, set isSaving = true when save starts, and isSaving = false when save completes
}

struct NavigationButtonsView: View {
  let currentStep: Int
  let backAction: () -> Void
  let nextAction: () -> Void
  let isNextDisabled: Bool

  var body: some View {
    VStack(spacing: 15) {
      StepNavigationButton(
        currentStep: currentStep,
        buttonText: currentStep == 5 ? "Complete Order" : "Next Step",
        isDisabled: isNextDisabled,
        action: nextAction
      )
    }
  }
}

// Create a typealias for backward compatibility
typealias FixedBottomNavigationView = StepNavigationContainer

struct StepNavigationComponents_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      // Preview for StepNavigationContainer (showing consolidated functionality)
      StepNavigationContainer(
        currentStep: 2,
        totalSteps: 6,
        nextButtonText: "Next Step",
        nextButtonDisabled: false,
        nextButtonAction: {},
        backButtonAction: {},
        cancelAction: {},
        disableBackButton: false,
        disableCancelButton: false
      ) {
        VStack(spacing: 20) {
          Text("Content goes here")
            .frame(maxWidth: .infinity, alignment: .center)
        }
      }

      // Another preview showing different step
      StepNavigationContainer(
        currentStep: 3,
        totalSteps: 6,
        nextButtonAction: {},
        backButtonAction: {},
        cancelAction: {}
      ) {
        VStack(alignment: .leading, spacing: 20) {
          Text("This is the content area")
            .font(.title)
            .fontWeight(.bold)

          Text("This is where the specific content for each step would go.")
            .foregroundColor(.secondary)

          // Example form fields or other content
          ForEach(1...3, id: \.self) { _ in
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.gray.opacity(0.2))
              .frame(height: 50)
          }
        }
      }
    }
  }
}

import SwiftUI

struct StepNavigationButton: View {
    // Parameters for customization
    let currentStep: Int
    let totalSteps: Int = 5
    let buttonText: String
    let isBackButton: Bool
    let action: () -> Void
    let isDisabled: Bool
    
    init(
        currentStep: Int,
        buttonText: String = "Next Step",
        isBackButton: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.currentStep = currentStep
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
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .background(
                Group {
                    if isDisabled {
                        Color.gray
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
        .disabled(isDisabled)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int = 5
    
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.accentGold)
                .frame(width: 120, height: 40)
            
            Text("STEP \(currentStep)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding(.top, 20)
    }
}

struct NavigationButtonsView: View {
    let currentStep: Int
    let backAction: () -> Void
    let nextAction: () -> Void
    let isNextDisabled: Bool
    
    var body: some View {
        VStack(spacing: 15) {
            // Only show back button if not on first step
            if currentStep > 1 {
                StepNavigationButton(
                    currentStep: currentStep,
                    buttonText: "Back",
                    isBackButton: true,
                    action: backAction
                )
            }
            
            StepNavigationButton(
                currentStep: currentStep,
                buttonText: currentStep == 5 ? "Complete" : "Next Step",
                isDisabled: isNextDisabled,
                action: nextAction
            )
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
    }
}

struct FixedBottomNavigationView<Content: View>: View {
    let content: Content
    let currentStep: Int
    let backAction: () -> Void
    let nextAction: () -> Void
    let isNextDisabled: Bool
    
    init(currentStep: Int, 
         backAction: @escaping () -> Void, 
         nextAction: @escaping () -> Void, 
         isNextDisabled: Bool, 
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.currentStep = currentStep
        self.backAction = backAction
        self.nextAction = nextAction
        self.isNextDisabled = isNextDisabled
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack {
                content
                Spacer(minLength: 100) // Space for the fixed navigation buttons
            }
            
            // Fixed navigation at bottom
            VStack {
                Spacer()
                
                // Navigation buttons
                VStack(spacing: 15) {
                    // Only show back button if not on first step
                    if currentStep > 1 {
                        StepNavigationButton(
                            currentStep: currentStep,
                            buttonText: "Back",
                            isBackButton: true,
                            action: backAction
                        )
                    }
                    
                    StepNavigationButton(
                        currentStep: currentStep,
                        buttonText: currentStep == 5 ? "Complete" : "Next Step",
                        isDisabled: isNextDisabled,
                        action: nextAction
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
                .background(
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .shadow(radius: 2)
                )
            }
        }
    }
}

struct StepNavigationButton_Previews: PreviewProvider {
    static var previews: some View {
        FixedBottomNavigationView(
            currentStep: 2, 
            backAction: {}, 
            nextAction: {}, 
            isNextDisabled: false
        ) {
            VStack(spacing: 20) {
                StepIndicator(currentStep: 2)
                Text("Content goes here")
                    .padding()
            }
            .padding()
        }
    }
}

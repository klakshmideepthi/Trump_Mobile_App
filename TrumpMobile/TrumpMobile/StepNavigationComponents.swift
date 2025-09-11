import SwiftUI

struct StepNavigationContainer<Content: View>: View {
    let currentStep: Int
    let totalSteps: Int
    let nextButtonText: String
    let nextButtonAction: () -> Void
    let backButtonAction: () -> Void
    let content: Content
    let nextButtonDisabled: Bool
    let cancelAction: (() -> Void)?
    @State private var showCancelConfirmation = false
    
    init(
        currentStep: Int,
        totalSteps: Int = 6,
        nextButtonText: String = "Next Step",
        nextButtonDisabled: Bool = false,
        nextButtonAction: @escaping () -> Void,
        backButtonAction: @escaping () -> Void,
        cancelAction: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.nextButtonText = nextButtonText
        self.nextButtonDisabled = nextButtonDisabled
        self.nextButtonAction = nextButtonAction
        self.backButtonAction = backButtonAction
        self.cancelAction = cancelAction
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Fixed header area with Step indicator
                VStack(spacing: 0) {
                    // Step indicator at top with back arrow and cancel button
                    HStack {
                        // Back button on left (hidden for step 1 and step 6)
                        Button(action: backButtonAction) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor((currentStep == 1 || currentStep == 6) ? Color.clear : Color.accentGold)
                                .padding()
                        }
                        .disabled(currentStep == 1 || currentStep == 6)
                        
                        Spacer()
                        
                        // Step indicator in center
                        ZStack {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 40)
                            
                            Text("STEP \(currentStep) OF \(totalSteps)")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                        }
                        
                        Spacer()
                        
                        // Cancel button on right
                        Button(action: {
                            print("DEBUG: Cancel button tapped in StepNavigationContainer")
                            if cancelAction != nil {
                                print("DEBUG: cancelAction exists in StepNavigationContainer")
                                showCancelConfirmation = true
                            } else {
                                print("DEBUG: cancelAction is nil in StepNavigationContainer when tapped")
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color.accentGold)
                                .padding()
                        }
                    }
                    .padding(.horizontal)
                }
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                // Content area (flexible)
                ScrollView {
                    content
                        .padding(.horizontal)  // Only add horizontal padding
                        .padding(.top, 8)      // Minimal top padding
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 100) // Add padding to ensure content isn't hidden behind button
                }
            }
            .background(Color(.systemGroupedBackground))
            
            // Fixed navigation button at bottom
            VStack(spacing: 0) {
                StepNavigationButton(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    buttonText: currentStep == 5 ? "Complete Order" : nextButtonText,
                    isDisabled: nextButtonDisabled,
                    action: nextButtonAction
                )
                .padding(.bottom, 20)
            }
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.bottom)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: -2)
            )
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
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
                secondaryButton: .cancel(Text("No"))
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ProgressBar: View {
    var value: Double // Between 0 and 1
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(.gray)
                
                Rectangle()
                    .frame(width: min(CGFloat(self.value) * geometry.size.width, geometry.size.width), height: geometry.size.height)
                    .foregroundColor(Color.accentGold)
            }
            .cornerRadius(45)
        }
    }
}

struct StepNavigationButton: View {
    // Parameters for customization
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
            .padding(.horizontal, 40)
            .padding(.vertical, 15)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
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
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .padding(.horizontal, 30)
        .disabled(isDisabled)
    }
}

struct StepIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    let showBackButton: Bool
    let onBack: (() -> Void)?
    
    init(currentStep: Int, totalSteps: Int = 6, showBackButton: Bool = false, onBack: (() -> Void)? = nil) {
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.showBackButton = showBackButton
        self.onBack = onBack
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if showBackButton {
                Button(action: {
                    onBack?()
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor((currentStep == 1 || currentStep == 6) ? Color.clear : Color.accentGold)
                        .font(.system(size: 20, weight: .semibold))
                }
                .disabled(currentStep == 1 || currentStep == 6)
            }
            
            Spacer()
            
            ZStack {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 40)
                
                Text("STEP \(currentStep) OF \(totalSteps)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Placeholder to balance the layout
            if showBackButton {
                Image(systemName: "xmark")
                    .font(.system(size: 20))
                    .foregroundColor(.clear)
            }
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .frame(height: 60) // Fixed height for consistent positioning
    }
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
        .padding(.bottom, 20)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
}

struct FixedBottomNavigationView<Content: View>: View {
    let content: Content
    let currentStep: Int
    let totalSteps: Int
    let backAction: () -> Void
    let nextAction: () -> Void
    let isNextDisabled: Bool
    let cancelAction: (() -> Void)?
    let disableBackButton: Bool
    let disableCancelButton: Bool
    let nextButtonText: String
    @State private var showCancelConfirmation = false
    
    init(currentStep: Int, 
         totalSteps: Int = 6,
         backAction: @escaping () -> Void, 
         nextAction: @escaping () -> Void, 
         isNextDisabled: Bool,
         cancelAction: (() -> Void)? = nil,
         disableBackButton: Bool = false,
         disableCancelButton: Bool = false,
         nextButtonText: String = "Next Step",
         @ViewBuilder content: () -> Content) {
        self.content = content()
        self.currentStep = currentStep
        self.totalSteps = totalSteps
        self.backAction = backAction
        self.nextAction = nextAction
        self.isNextDisabled = isNextDisabled
        self.cancelAction = cancelAction
        self.disableBackButton = disableBackButton
        self.disableCancelButton = disableCancelButton
        self.nextButtonText = nextButtonText
        
        // Enhanced debug logging
        print("DEBUG: FixedBottomNavigationView init - cancelAction parameter: \(cancelAction == nil ? "nil" : "not nil")")
        print("DEBUG: FixedBottomNavigationView init - self.cancelAction: \(self.cancelAction == nil ? "nil" : "not nil")")
        print("DEBUG: FixedBottomNavigationView init - currentStep: \(currentStep)")
        print("DEBUG: FixedBottomNavigationView init - disableCancelButton: \(disableCancelButton)")
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                // Fixed header with back button, step indicator, and cancel button
                HStack {
                    // Back button on left (hidden for step 1 and step 6)
                    Button(action: backAction) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor((currentStep == 1 || currentStep == 6 || disableBackButton) ? Color.clear : Color.accentGold)
                            .padding()
                    }
                    .disabled(currentStep == 1 || currentStep == 6 || disableBackButton)
                    
                    Spacer()
                    
                    // Step indicator in center
                    ZStack {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 40)
                        
                        Text("STEP \(currentStep) OF \(totalSteps)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                    }
                    
                    Spacer()
                    
                    // Cancel button on right
                    Button(action: {
                        print("DEBUG: Cancel button tapped in FixedBottomNavigationView")
                        print("DEBUG: Is cancelAction nil? \(cancelAction == nil ? "Yes" : "No")")
                        if let cancelAction = cancelAction {
                            print("DEBUG: cancelAction exists in FixedBottomNavigationView - showing confirmation")
                            showCancelConfirmation = true
                        } else {
                            print("DEBUG: cancelAction is nil in FixedBottomNavigationView - not showing confirmation")
                            // Re-check if self.cancelAction is nil
                            print("DEBUG: Double-checking self.cancelAction: \(self.cancelAction == nil ? "nil" : "not nil")")
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(disableCancelButton ? Color.clear : Color.accentGold)
                            .padding()
                    }
                    .disabled(disableCancelButton)
                }
                .padding(.horizontal)
                .background(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)
                
                // Main content
                ScrollView {
                    content
                        .padding(.horizontal)  // Only add horizontal padding
                        .padding(.top, 8)      // Minimal top padding
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 100) // Add padding to ensure content isn't hidden behind the button
                }
                .background(Color(.systemGroupedBackground))
            }
            
            // Fixed navigation button at bottom
            VStack(spacing: 0) {
                StepNavigationButton(
                    currentStep: currentStep,
                    totalSteps: totalSteps,
                    buttonText: nextButtonText == "Next Step" && currentStep == 5 ? "Complete Order" : nextButtonText,
                    isDisabled: isNextDisabled,
                    action: nextAction
                )
                .padding(.bottom, 20)
            }
            .background(
                Rectangle()
                    .fill(Color(.systemBackground))
                    .edgesIgnoringSafeArea(.bottom)
                    .shadow(color: Color.black.opacity(0.1), radius: 5, y: -2)
            )
        }
        .background(Color(.systemGroupedBackground))
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: $showCancelConfirmation) {
            Alert(
                title: Text("Cancel Order"),
                message: Text("Do you want to cancel the order?"),
                primaryButton: .destructive(Text("Yes, I want to cancel")) {
                    print("DEBUG: Cancel button pressed in FixedBottomNavigationView")
                    if let cancelAction = cancelAction {
                        print("DEBUG: Executing cancelAction in FixedBottomNavigationView")
                        cancelAction()
                    } else {
                        print("DEBUG: cancelAction is nil in FixedBottomNavigationView")
                    }
                },
                secondaryButton: .cancel(Text("No"))
            )
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct StepNavigationComponents_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for FixedBottomNavigationView
            FixedBottomNavigationView(
                currentStep: 2,
                totalSteps: 6,
                backAction: {}, 
                nextAction: {}, 
                isNextDisabled: false,
                cancelAction: {},
                disableBackButton: false,
                disableCancelButton: false,
                nextButtonText: "Next Step"
            ) {
                VStack(spacing: 20) {
                    // Removed duplicate StepIndicator
                    Text("Content goes here")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            
            // Preview for StepNavigationContainer
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

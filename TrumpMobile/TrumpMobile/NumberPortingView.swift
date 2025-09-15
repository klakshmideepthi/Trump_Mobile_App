import SwiftUI

struct NumberPortingView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var showNavigation: Bool = true
    
    @State private var showSIMSetup = false
    
    var body: some View {
        Group {
            if shouldShowPortIn && !showSIMSetup {
                // Show porting view first for existing numbers
                PortingView(
                    viewModel: viewModel,
                    onNext: {
                        // After porting proceeds, show SIM setup in the same step
                        showSIMSetup = true
                    },
                    onBack: onBack,
                    onCancel: onCancel,
                    showNavigation: showNavigation
                )
            } else {
                // Show SIM setup (either after porting or directly for new numbers)
                SIMSetupView(
                    viewModel: viewModel,
                    onNext: onNext, // This completes Step 6
                    onBack: shouldShowPortIn ? {
                        // If we came from porting, go back to porting view
                        showSIMSetup = false
                    } : onBack, // If new number, go back to previous step
                    onCancel: onCancel,
                    showNavigation: showNavigation
                )
            }
        }
    }
    
    private var shouldShowPortIn: Bool {
        viewModel.numberType == "Existing" || 
        viewModel.numberType.lowercased().contains("existing") || 
        viewModel.numberType.lowercased().contains("transfer")
    }
}

#Preview {
    NumberPortingView(
        viewModel: UserRegistrationViewModel(),
        onNext: {}
    )
}
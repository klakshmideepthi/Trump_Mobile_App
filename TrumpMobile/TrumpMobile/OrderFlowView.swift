import SwiftUI
import FirebaseAuth

struct OrderFlowView: View {
    @State private var currentStep = 1
    @State private var currentOrder: Order?
    @EnvironmentObject private var navigationState: NavigationState
    @StateObject private var viewModel = UserRegistrationViewModel()
    private let orderManager = FirebaseOrderManager()
    
    init(startStep: Int = 1, orderId: String? = nil) {
        print("DEBUG: OrderFlowView initializing with startStep: \(startStep), orderId: \(orderId ?? "nil")")
        _currentStep = State(initialValue: startStep)
        if let id = orderId {
            _currentOrder = State(initialValue: Order(id: id))
            print("DEBUG: OrderFlowView setting currentOrder with ID: \(id)")
        }
    }
    
    var body: some View {
        // Create a strong reference to the cancel closure
        let cancelActionClosure: () -> Void = {
            print("DEBUG: Cancel action triggered from OrderFlowView closure")
            handleCancelOrder()
        }
        
        // Verify the closure is non-nil before passing
        print("DEBUG: OrderFlowView creating FixedBottomNavigationView with cancelActionClosure")
        print("DEBUG: Is cancelActionClosure nil? \(cancelActionClosure == nil ? "Yes" : "No")")
        
        return FixedBottomNavigationView(
            currentStep: currentStep,
            totalSteps: 6,
            backAction: handleBackAction,
            nextAction: handleNextAction,
            isNextDisabled: false,
            cancelAction: cancelActionClosure,
            nextButtonText: "Next Step"
        ) {
            // Your order flow content based on current step
            VStack {
                switch currentStep {
                case 1:
                    ContactInfoView(
                        viewModel: viewModel,
                        onNext: { handleNextAction() }
                    )
                case 2:
                    DeviceCompatibilityView(
                        viewModel: viewModel,
                        onNext: { 
                            viewModel.saveDeviceInfo { success in
                                if success {
                                    handleNextAction()
                                }
                            }
                        },
                        onBack: { handleBackAction() },
                        onCancel: { 
                            print("DEBUG: Cancel from DeviceCompatibilityView")
                            handleCancelOrder() 
                        }
                    )
                case 3:
                    SimSelectionView(
                        viewModel: viewModel,
                        onNext: { 
                            viewModel.saveSimSelection { success in
                                if success {
                                    handleNextAction()
                                }
                            }
                        },
                        onBack: { handleBackAction() },
                        onCancel: { 
                            print("DEBUG: Cancel from SimSelectionView")
                            handleCancelOrder() 
                        }
                    )
                case 4:
                    NumberSelectionView(
                        viewModel: viewModel,
                        onNext: { 
                            viewModel.saveNumberSelection { success in
                                if success {
                                    handleNextAction()
                                }
                            }
                        },
                        onBack: { handleBackAction() },
                        onCancel: {
                            print("DEBUG: Cancel from NumberSelectionView")
                            handleCancelOrder()
                        }
                    )
                case 5:
                    BillingInfoView(
                        viewModel: viewModel,
                        onNext: { 
                            viewModel.saveBillingInfo { success in
                                if success {
                                    handleNextAction()
                                }
                            }
                        },
                        onBack: { handleBackAction() }
                    )
                case 6:
                    OrderCompletionView(
                        viewModel: viewModel,
                        onBack: { handleBackAction() },
                        onGoToHome: { 
                            // Reset to start a new order
                            navigationState.navigateTo(.startNewOrder)
                        }
                    )
                default:
                    Text("Invalid step")
                }
            }
        }
        .onAppear {
            print("DEBUG: OrderFlowView appeared with currentStep: \(currentStep)")
            print("DEBUG: OrderFlowView has currentOrder: \(currentOrder != nil ? "yes" : "no")")
            print("DEBUG: OrderFlowView has viewModel.orderId: \(viewModel.orderId ?? "nil")")
            
            // Testing the handleCancelOrder method is accessible
            print("DEBUG: Testing if handleCancelOrder is accessible in onAppear")
            let testCancelClosure: () -> Void = {
                print("DEBUG: Test cancel closure is executing")
            }
            print("DEBUG: Test cancel closure created successfully")
        }
    }
    
    private func handleCancelOrder() {
        print("DEBUG: handleCancelOrder called in OrderFlowView")
        print("DEBUG: handleCancelOrder accessing navigationState object")
        
        // First delete the order if it exists
        if let orderId = currentOrder?.id ?? viewModel.orderId {
            print("DEBUG: Deleting order with ID: \(orderId)")
            orderManager.deleteOrder(orderId: orderId) { success in
                if success {
                    print("DEBUG: Order successfully deleted from Firebase")
                } else {
                    print("DEBUG: Failed to delete order from Firebase")
                }
                
                // Navigate to Home view regardless of deletion success
                print("DEBUG: About to call navigationState.navigateTo(.home)")
                DispatchQueue.main.async {
                    print("DEBUG: Inside DispatchQueue.main.async before navigation")
                    self.navigationState.navigateTo(.home)
                    print("DEBUG: After navigationState.navigateTo(.home) call")
                }
            }
        } else {
            // No order created yet, just navigate back to home
            print("DEBUG: No order ID exists, just navigating back to home")
            DispatchQueue.main.async {
                print("DEBUG: Inside DispatchQueue.main.async before navigation (no order)")
                self.navigationState.navigateTo(.home)
                print("DEBUG: After navigationState.navigateTo(.home) call (no order)")
            }
        }
    }
    
    private func handleBackAction() {
        if currentStep > 1 {
            currentStep -= 1
        }
    }
    
    private func handleNextAction() {
        if currentStep < 6 {
            currentStep += 1
        } else {
            // Complete order flow
            navigationState.navigateTo(.startNewOrder)
        }
    }
}

// Simple Order model
struct Order: Identifiable {
    let id: String
    // Add other properties as needed
}

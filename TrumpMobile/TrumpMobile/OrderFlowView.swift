import FirebaseAnalytics
import FirebaseAuth
import SwiftUI

struct OrderFlowView: View {
  @State private var currentStep = 1
  @State private var currentOrder: FlowOrder?
  @EnvironmentObject private var navigationState: NavigationState
  @StateObject private var viewModel = UserRegistrationViewModel()
  @StateObject private var notificationManager = NotificationManager.shared
  private let orderManager = FirebaseOrderManager.shared

  init(startStep: Int = 1, orderId: String? = nil) {
    print(
      "DEBUG: OrderFlowView initializing with startStep: \(startStep), orderId: \(orderId ?? "nil")"
    )
    _currentStep = State(initialValue: startStep)
    if let id = orderId {
      _currentOrder = State(initialValue: FlowOrder(id: id))
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

    return StepNavigationContainer(
      currentStep: currentStep,
      totalSteps: 6,
      nextButtonText: "Next Step",
      nextButtonDisabled: false,
      nextButtonAction: handleNextAction,
      backButtonAction: handleBackAction,
      cancelAction: cancelActionClosure
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
            },
            showNavigation: false  // Don't show navigation since it's already provided by FixedBottomNavigationView
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
            },
            showNavigation: false  // Don't show navigation since it's already provided by FixedBottomNavigationView
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
            },
            showNavigation: false  // Don't show navigation since it's already provided by FixedBottomNavigationView
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
          NumberPortingView(
            viewModel: viewModel,
            onNext: {
              // Reset to start a new order
              navigationState.navigateTo(.startNewOrder)
            },
            onBack: { handleBackAction() },
            onCancel: {
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

      // Log order started event for FIAM when starting a new order
      if currentStep == 1 && currentOrder == nil {
        print("🔄 Resetting order-specific fields for new order")
        viewModel.resetOrderSpecificFields()
        viewModel.userId = Auth.auth().currentUser?.uid

        // Check if we have a valid order ID - if not, show error
        if viewModel.orderId == nil {
          viewModel.errorMessage = "There's a problem with loading the order. Please try again."
          print("❌ No order ID available for new order flow")
          return
        }

        // Log analytics event for new order
        notificationManager.logOrderStarted()
      } else if let orderId = currentOrder?.id {
        print("🔄 Setting orderId in viewModel: \(orderId)")
        viewModel.orderId = orderId
        viewModel.userId = Auth.auth().currentUser?.uid
      } else {
        // If we're not at step 1 and don't have an order ID, this is an error
        viewModel.errorMessage = "There's a problem with loading the order. Please try again."
        print("❌ No order ID available for continuing order flow")
      }

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
    // Log step completion before moving to next step
    notificationManager.logStepCompleted(step: currentStep)

    if currentStep < 6 {
      currentStep += 1
    } else {
      // We're at step 6 - let the step handle its own completion logic
      // Don't automatically navigate away
      print("DEBUG: At step 6, letting step handle its own completion")

      // Log order completed event
      notificationManager.logOrderCompleted()
      print("DEBUG: At step 6, letting step handle its own completion")

    }
  }
}

// Simple Order model for flow tracking
struct FlowOrder: Identifiable {
  let id: String
  // Add other properties as needed
}

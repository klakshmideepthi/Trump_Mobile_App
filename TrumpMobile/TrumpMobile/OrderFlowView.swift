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

    print("DEBUG: OrderFlowView creating StepNavigationContainer with cancelActionClosure")

    return StepNavigationContainer(
      currentStep: currentStep,
      totalSteps: 6,
      nextButtonText: "Next Step",
      nextButtonDisabled: false,
      nextButtonAction: handleNextAction,
      backButtonAction: handleBackAction,
      cancelAction: cancelActionClosure
    ) {
      VStack {
        switch currentStep {
        case 1:
          ContactInfoView(
            viewModel: viewModel,
            onNext: {
              saveProgress(step: 1)
              handleNextAction()
            }
          )

        case 2:
          DeviceCompatibilityView(
            viewModel: viewModel,
            onNext: {
              viewModel.saveDeviceInfo { success in
                if success {
                  saveProgress(step: 2)
                  handleNextAction()
                }
              }
            },
            onBack: { handleBackAction() },
            onCancel: {
              print("DEBUG: Cancel from DeviceCompatibilityView")
              handleCancelOrder()
            },
            showNavigation: false
          )

        case 3:
          SimSelectionView(
            viewModel: viewModel,
            onNext: {
              viewModel.saveSimSelection { success in
                if success {
                  saveProgress(step: 3)
                  handleNextAction()
                }
              }
            },
            onBack: { handleBackAction() },
            onCancel: {
              print("DEBUG: Cancel from SimSelectionView")
              handleCancelOrder()
            },
            showNavigation: false
          )

        case 4:
          NumberSelectionView(
            viewModel: viewModel,
            onNext: {
              viewModel.saveNumberSelection { success in
                if success {
                  saveProgress(step: 4)
                  handleNextAction()
                }
              }
            },
            onBack: { handleBackAction() },
            onCancel: {
              print("DEBUG: Cancel from NumberSelectionView")
              handleCancelOrder()
            },
            showNavigation: false
          )

        case 5:
          BillingInfoView(
            viewModel: viewModel,
            onNext: {
              viewModel.saveBillingInfo { success in
                if success {
                  saveProgress(step: 5)
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
              viewModel.completeOrder { success in
                if let userId = viewModel.userId, let orderId = viewModel.orderId, success {
                  orderManager.markOrderCompleted(userId: userId, orderId: orderId, completion: nil)
                }
                navigationState.navigateTo(.startNewOrder)
              }
            },
            onBack: { handleBackAction() },
            onCancel: {
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

      if currentStep == 1 && currentOrder == nil {
        print("🔄 Resetting order-specific fields for new order")
        viewModel.resetOrderSpecificFields()
        viewModel.userId = Auth.auth().currentUser?.uid

        if viewModel.orderId == nil {
          viewModel.errorMessage = "There's a problem with loading the order. Please try again."
          print("❌ No order ID available for new order flow")
          return
        }

        notificationManager.logOrderStarted()
      } else if let orderId = currentOrder?.id {
        print("🔄 Setting orderId in viewModel: \(orderId)")
        viewModel.orderId = orderId
        viewModel.userId = Auth.auth().currentUser?.uid
      } else {
        viewModel.errorMessage = "There's a problem with loading the order. Please try again."
        print("❌ No order ID available for continuing order flow")
      }

      // Apply resume only once per order to avoid overriding user's backfill edits
      if let resumeOrderId = navigationState.currentOrderId {
        // Only apply the resume step for this order if we haven't already
        if navigationState.lastAppliedResumeForOrderId != resumeOrderId {
          if let resumeStep = navigationState.orderStartStep {
            self.currentStep = max(1, min(6, resumeStep))
          }
          navigationState.lastAppliedResumeForOrderId = resumeOrderId
        }

        // Ensure local state aligns with the resumed order and hydrate once
        if viewModel.orderId != resumeOrderId {
          self.currentOrder = FlowOrder(id: resumeOrderId)
          self.viewModel.orderId = resumeOrderId
          // Prefill the view model with existing order data once
          self.viewModel.prefillFromOrder(orderId: resumeOrderId, completion: nil)
        }
        // Do not clear orderStartStep/currentOrderId immediately; let it be available for other views if needed
      }

      print("DEBUG: Testing if handleCancelOrder is accessible in onAppear")
      let testCancelClosure: () -> Void = {
        print("DEBUG: Test cancel closure is executing")
      }
      print("DEBUG: Test cancel closure created successfully: \(testCancelClosure)")
    }
  }

  private func handleCancelOrder() {
    print("DEBUG: handleCancelOrder called in OrderFlowView")
    print("DEBUG: handleCancelOrder accessing navigationState object")

    if let orderId = currentOrder?.id ?? viewModel.orderId {
      print("DEBUG: Deleting order with ID: \(orderId)")
      orderManager.deleteOrder(orderId: orderId) { success in
        if success {
          print("DEBUG: Order successfully deleted from Firebase")
        } else {
          print("DEBUG: Failed to delete order from Firebase")
        }
        DispatchQueue.main.async {
          print("DEBUG: Inside DispatchQueue.main.async before navigation")
          self.navigationState.navigateTo(.home)
          print("DEBUG: After navigationState.navigateTo(.home) call")
        }
      }
    } else {
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
    notificationManager.logStepCompleted(step: currentStep)

    if currentStep < 6 {
      currentStep += 1
    } else {
      print("DEBUG: At step 6, letting step handle its own completion")
      notificationManager.logOrderCompleted()
    }
  }

  private func saveProgress(step: Int) {
    guard let userId = viewModel.userId, let orderId = viewModel.orderId else { return }
    orderManager.saveStepProgress(userId: userId, orderId: orderId, step: step) { result in
      if case .failure(let error) = result {
        print("⚠️ Failed to save step progress: \(error.localizedDescription)")
      }
    }
  }
}

// Simple Order model for flow tracking
struct FlowOrder: Identifiable {
  let id: String
}

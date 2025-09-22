import Foundation
import SwiftUI

class NavigationState: ObservableObject {
  enum Destination: CustomStringConvertible {
    case splash
    case login
    case startNewOrder
    case orderFlow
    case orderDetails
    case home
    // Add other destinations as needed

    var description: String {
      switch self {
      case .splash: return "splash"
      case .login: return "login"
      case .startNewOrder: return "startNewOrder"
      case .orderFlow: return "orderFlow"
      case .orderDetails: return "orderDetails"
      case .home: return "home"
      }
    }
  }

  // Add published property for splash state
  @Published var showSplash: Bool = false
  @Published var showPreviousOrders: Bool = false
  @Published var showContactInfoDetail: Bool = false
  @Published var showInternationalLongDistance: Bool = false
  @Published var showPrivacyPolicy: Bool = false
  @Published var showTermsAndConditions: Bool = false
  // Order resume support
  @Published var currentOrderId: String? = nil
  @Published var orderStartStep: Int? = nil
  // Track which order's resume step has already been applied to avoid re-applying
  @Published var lastAppliedResumeForOrderId: String? = nil

  init() {
    print("DEBUG: NavigationState initialized with destination: \(currentDestination)")
  }

  @Published var currentDestination: Destination = .startNewOrder {
    didSet {
      print("DEBUG: NavigationState destination changed from \(oldValue) to \(currentDestination)")
    }
  }

  func navigateTo(_ destination: Destination) {
    print("DEBUG: NavigationState.navigateTo called with destination: \(destination)")
    print("DEBUG: Current destination before change: \(self.currentDestination)")
    self.currentDestination = destination
    print("DEBUG: Current destination after change: \(self.currentDestination)")
  }

  // Resume helpers
  func resumeOrder(orderId: String, at step: Int) {
    currentOrderId = orderId
    orderStartStep = step
    navigateTo(.orderFlow)
  }

  func clearOrderResume() {
    orderStartStep = nil
  }

  func handleOrderCancellation() {
    print("DEBUG: NavigationState.handleOrderCancellation called")
    // Simply navigate to home screen
    DispatchQueue.main.async {
      print("DEBUG: Inside handleOrderCancellation's DispatchQueue.main.async")
      self.navigateTo(.home)
      print("DEBUG: After navigateTo(.home) call in handleOrderCancellation")
    }
  }

  // Reset all navigation states to initial values
  func resetNavigation() {
    showSplash = false
    showPreviousOrders = false
    showContactInfoDetail = false
    showInternationalLongDistance = false
    showPrivacyPolicy = false
    showTermsAndConditions = false
  }

  // Reset to login state after logout
  func resetToLogin() {
    print("DEBUG: NavigationState.resetToLogin called")
    currentDestination = .login
    showSplash = true
    resetNavigation()
  }

  // New method to show splash screen
  func showSplashScreen() {
    print("DEBUG: NavigationState.showSplashScreen called")
    currentDestination = .splash
    showSplash = true
    resetNavigation()
  }

  // Reset all state when user logs out
  func reset() {
    print("DEBUG: NavigationState.reset called")
    currentDestination = .splash
    showSplash = false
    showPreviousOrders = false
    showContactInfoDetail = false
    showInternationalLongDistance = false
    showPrivacyPolicy = false
    showTermsAndConditions = false
  }
}

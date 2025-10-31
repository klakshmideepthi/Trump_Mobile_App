import FirebaseAuth
import SwiftUI

struct SplashView: View {
  @State private var isLoggedIn = false
  @State private var isLoading = true
  @State private var isNewAccount: Bool? = nil // Changed: isNewAccount now handled in SplashView
  @State private var initialOrderStep: Int? = nil
  @EnvironmentObject private var navigationState: NavigationState
  @StateObject private var notificationManager = NotificationManager.shared
  @StateObject private var viewModel = UserRegistrationViewModel()

  var body: some View {
    Group {
      if isLoading {
        // Show splash screen while checking auth state
        VStack {
          Spacer()
          Image("Trump_Mobile_logo_gold")
            .resizable()
            .scaledToFit()
            .frame(width: 220, height: 220)
            .accessibilityLabel("Telgoo5 Mobile") // Clear brand label for VO
          ProgressView()
            .padding(.top, 16)
            .accessibilityLabel("Loading")
          Spacer()
        }
        .background(Color.adaptiveBackground)
        .ignoresSafeArea()
      } else if isLoggedIn, let newAccount = isNewAccount, let startStep = initialOrderStep {
        ContentView(isNewAccount: newAccount, initialOrderStep: startStep)
          .environmentObject(viewModel)
      } else if !isLoggedIn {
        LoginView(
          onSignIn: {
            isLoggedIn = true
            isNewAccount = nil
            isLoading = true
            initialOrderStep = nil
            checkAuthenticationState()
          }
        )
      } else {
        EmptyView()
      }
    }
    .onAppear {
      setupSplashScreen()
      checkAuthenticationState()
    }
    .onReceive(NotificationCenter.default.publisher(for: .authStateDidChange)) { _ in
      checkAuthenticationState()
    }
  }

  private func setupSplashScreen() {
    // Request notification permission when app starts
    notificationManager.requestPermission()

    // Log app opened event for FIAM
    notificationManager.logAppOpened()
  }

  private func checkAuthenticationState() {
    // Add a small delay to ensure Firebase Auth is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      if let user = Auth.auth().currentUser {
        isLoggedIn = true
        viewModel.userId = user.uid
        viewModel.loadUserData { _ in
          // Determine if new or existing user by order fetch
          viewModel.fetchPreviousOrders { orders in
            isNewAccount = (orders == nil || orders!.isEmpty)
            FirebaseOrderManager.shared.fetchLatestIncompleteOrder(for: user.uid) { result in
              switch result {
              case .success(let info):
                initialOrderStep = max(1, min(6, info.currentStep))
                viewModel.orderId = info.orderId
                viewModel.prefillFromOrder(orderId: info.orderId, completion: nil)
              case .failure:
                initialOrderStep = 0
              }
              // Show splash for minimum time
              let minimumSplashTime: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0.8 : 1.6
              DispatchQueue.main.asyncAfter(deadline: .now() + minimumSplashTime) {
                isLoading = false
              }
            }
          }
        }
        // Attempt to resume latest incomplete order (optional, can keep here...)
        // Removed navigationState.resumeOrder call
        // Send welcome notification for authenticated users if needed
        if isLoading {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            notificationManager.sendWelcomeNotification()
          }
        }
      } else {
        isLoggedIn = false
        isNewAccount = nil
        initialOrderStep = nil
        navigationState.reset()
        viewModel.reset()
        // Show splash for minimum time
        let minimumSplashTime: TimeInterval = UIAccessibility.isReduceMotionEnabled ? 0.8 : 1.6
        DispatchQueue.main.asyncAfter(deadline: .now() + minimumSplashTime) {
          isLoading = false
        }
      }
    }
  }
}

#Preview {
  SplashView()
    .environmentObject(NavigationState())
}

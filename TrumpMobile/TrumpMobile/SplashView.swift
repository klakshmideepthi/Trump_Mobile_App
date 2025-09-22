import FirebaseAuth
import SwiftUI

struct SplashView: View {
  @State private var isLoggedIn = false
  @State private var isLoading = true
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
            .frame(width: 280, height: 280)
          Spacer()
        }
        .background(Color(.systemBackground))
        .ignoresSafeArea()
      } else if isLoggedIn {
        ContentView()
          .environmentObject(viewModel)
      } else {
        LoginView(
          onSignIn: {
            isLoggedIn = true
          }
        )
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
        print("🔍 User is signed in: \(user.email ?? "unknown")")
        isLoggedIn = true

        // Load user data
        viewModel.userId = user.uid
        viewModel.loadUserData { _ in }

        // Attempt to resume latest incomplete order
        FirebaseOrderManager.shared.fetchLatestIncompleteOrder(for: user.uid) { result in
          switch result {
          case .success(let info):
            print(
              "➡️ Found in-progress order to resume: id=\(info.orderId) step=\(info.currentStep)")
            navigationState.resumeOrder(orderId: info.orderId, at: max(1, info.currentStep))
          case .failure:
            break
          }
        }

        // Send welcome notification for authenticated users if needed
        if isLoading {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            notificationManager.sendWelcomeNotification()
          }
        }
      } else {
        print("🔍 User is not signed in")
        isLoggedIn = false

        // Reset navigation state and view models when user is not logged in
        navigationState.reset()
        viewModel.reset()
      }

      // Show splash for minimum time, then hide loading state
      let minimumSplashTime: TimeInterval = isLoading ? 2.0 : 0.5
      DispatchQueue.main.asyncAfter(deadline: .now() + minimumSplashTime) {
        isLoading = false
      }
    }
  }
}

#Preview {
  SplashView()
    .environmentObject(NavigationState())
}

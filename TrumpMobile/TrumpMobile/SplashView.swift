import FirebaseAuth
import SwiftUI

struct SplashView: View {
  @State private var isActive = false
  @State private var isSignedIn = false
  @State private var authStateListener: AuthStateDidChangeListenerHandle?

  @StateObject private var notificationManager = NotificationManager.shared
  @StateObject private var viewModel = UserRegistrationViewModel()
  @EnvironmentObject private var navigationState: NavigationState

  var body: some View {
    if isActive {
      VStack(spacing: 0) {
        if !isSignedIn {
          LoginView(
            onSignIn: {
              isSignedIn = true
            }
          )
        } else {
          ContentView()
            .environmentObject(viewModel)
        }
      }
    } else {
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
      .onAppear {
        setupSplashScreen()
      }
      .onDisappear {
        // Remove listener when view disappears
        if let handle = authStateListener {
          Auth.auth().removeStateDidChangeListener(handle)
        }
      }
    }
  }

  private func setupSplashScreen() {
    // Request notification permission when app starts
    notificationManager.requestPermission()

    // Log app opened event for FIAM
    notificationManager.logAppOpened()

    // Set up auth state listener
    authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
      DispatchQueue.main.async {
        isSignedIn = user != nil

        // If user is signed in
        if let user = user {
          // Send welcome notification for new users
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            notificationManager.sendWelcomeNotification()
          }

          // Load user data if necessary
          viewModel.userId = user.uid
          viewModel.loadUserData { _ in }

        }
      }
    }

    // Delay splash screen
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      withAnimation {
        isActive = true
      }
    }
  }
}

#Preview {
  SplashView()
    .environmentObject(NavigationState())
}

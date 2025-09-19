import Foundation
import FirebaseAuth

extension Notification.Name {
  static let authStateDidChange = Notification.Name("authStateDidChange")
}

class AuthStateManager {
  static let shared = AuthStateManager()
  private var authStateHandle: AuthStateDidChangeListenerHandle?

  private init() {
    setupAuthStateListener()
  }

  private func setupAuthStateListener() {
    authStateHandle = Auth.auth().addStateDidChangeListener { _, user in
      DispatchQueue.main.async {
        print("DEBUG: Auth state changed, user: \(user?.email ?? "nil")")
        NotificationCenter.default.post(name: .authStateDidChange, object: user)
      }
    }
  }

  deinit {
    if let handle = authStateHandle {
      Auth.auth().removeStateDidChangeListener(handle)
    }
  }
}
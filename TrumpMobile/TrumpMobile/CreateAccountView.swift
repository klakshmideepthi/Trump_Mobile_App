import AuthenticationServices
import CryptoKit
import Firebase
import FirebaseAuth
import GoogleSignIn
import SwiftUI

struct CreateAccountView: View {
  @Environment(\.dismiss) private var dismiss
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onAccountCreated: (() -> Void)? = nil

  @State private var showError = false
  @State private var errorMessage = ""

  // Apple Sign-In nonce (required by Firebase)
  @State private var currentNonce: String?

  var body: some View {
    NavigationStack {
      VStack(spacing: 24) {
        Image("Trump_Mobile_logo_gold")
          .resizable()
          .scaledToFit()
          .frame(width: 120, height: 120)
          .padding(.top, 40)

        VStack(spacing: 16) {
          TextField("Email", text: $viewModel.email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled(true)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

          SecureField("Password", text: $viewModel.password)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)

          SecureField("Confirm Password", text: $viewModel.confirmPassword)
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(8)
        }
        .padding(.horizontal)

        Button {
          createAccount()
        } label: {
          Text("Create Account")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal)

        HStack {
          Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.4))
          Text("OR").foregroundColor(.gray)
          Rectangle().frame(height: 1).foregroundColor(.gray.opacity(0.4))
        }
        .padding(.horizontal)

        Button {
          signUpWithGoogle()
        } label: {
          HStack {
            Image(systemName: "globe")
            Text("Sign up with Google")
          }
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.9))
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .padding(.horizontal)

        // Apple Sign Up Button
        SignInWithAppleButton { request in
          let nonce = randomNonceString()
          currentNonce = nonce
          request.requestedScopes = [.fullName, .email]
          request.nonce = sha256(nonce)
        } onCompletion: { result in
          handleAppleSignUp(result: result)
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(8)
        .padding(.horizontal)

        HStack(spacing: 4) {
          Text("Already have an account?")
          Button("Sign In") { dismiss() }
        }
        .padding(.top, 8)

        Spacer()
      }
      .navigationTitle("Create Account")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
        }
      }
      .alert(isPresented: $showError) {
        Alert(
          title: Text("Error"),
          message: Text(errorMessage),
          dismissButton: .default(Text("OK"))
        )
      }
    }
    .navigationBarBackButtonHidden()
  }

  private func createAccount() {
    // Basic validation
    guard !viewModel.email.isEmpty else {
      show(error: "Please enter your email address.")
      return
    }

    guard !viewModel.password.isEmpty else {
      show(error: "Please enter a password.")
      return
    }

    guard viewModel.password == viewModel.confirmPassword else {
      show(error: "Passwords do not match.")
      return
    }

    // Create account in Firebase
    Auth.auth().createUser(withEmail: viewModel.email, password: viewModel.password) {
      result, error in
      if let error = error {
        show(error: error.localizedDescription)
        return
      }

      // Update user registration model
      if let user = result?.user {
        viewModel.userId = user.uid
        onAccountCreated?()
      } else {
        show(error: "Failed to create account.")
      }
    }
  }

  // MARK: - Google Sign-Up
  private func signUpWithGoogle() {
    guard let clientID = FirebaseApp.app()?.options.clientID else {
      show(error: "Missing Google Client ID.")
      return
    }

    // Configure once (safe to reassign)
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

    guard let rootVC = rootViewController() else {
      show(error: "Unable to find a presenting view controller.")
      return
    }

    GIDSignIn.sharedInstance.signIn(withPresenting: rootVC) { signInResult, error in
      if let error = error {
        self.show(error: error.localizedDescription)
        return
      }

      guard
        let idToken = signInResult?.user.idToken?.tokenString,
        let accessToken = signInResult?.user.accessToken.tokenString,
        signInResult?.user.profile?.email != nil
      else {
        self.show(error: "Google authentication failed.")
        return
      }

      let credential = GoogleAuthProvider.credential(
        withIDToken: idToken,
        accessToken: accessToken)

      // Skip the check for existing accounts and directly try to sign in
      // The error handling will tell us if the account already exists
      Auth.auth().signIn(with: credential) { authResult, error in
        if let error = error {
          self.show(error: error.localizedDescription)
          return
        }

        // Update user registration model
        if let user = authResult?.user {
          self.viewModel.userId = user.uid
          self.viewModel.email = user.email ?? ""
          self.viewModel.accountType = "Google"
          self.onAccountCreated?()
        } else {
          self.show(error: "Failed to create account.")
        }
      }
    }
  }

  // MARK: - Apple Sign-Up
  private func handleAppleSignUp(result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let auth):
      guard
        let appleIDCred = auth.credential as? ASAuthorizationAppleIDCredential,
        let identityToken = appleIDCred.identityToken,
        let tokenString = String(data: identityToken, encoding: .utf8),
        appleIDCred.email != nil
      else {
        show(error: "Apple Sign-Up failed. Please try again.")
        return
      }

      let nonce = currentNonce ?? ""
      let credential = OAuthProvider.appleCredential(
        withIDToken: tokenString,
        rawNonce: nonce,
        fullName: appleIDCred.fullName)

      // Skip checking if user exists and directly try to sign in
      Auth.auth().signIn(with: credential) { authResult, error in
        if let error = error {
          self.show(error: error.localizedDescription)
          return
        }

        // Update user registration model
        if let user = authResult?.user {
          self.viewModel.userId = user.uid
          self.viewModel.email = user.email ?? appleIDCred.email ?? ""
          self.viewModel.accountType = "Apple"

          // If we have the fullName
          if let fullName = appleIDCred.fullName {
            self.viewModel.firstName = fullName.givenName ?? ""
            self.viewModel.lastName = fullName.familyName ?? ""
          }

          self.onAccountCreated?()
        } else {
          self.show(error: "Failed to create account.")
        }
      }

    case .failure(let error):
      show(error: error.localizedDescription)
    }
  }

  private func show(error: String) {
    errorMessage = error
    showError = true
  }

  private func rootViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap { $0.windows }
      .first { $0.isKeyWindow }?
      .rootViewController
  }

  // MARK: - Nonce utilities
  private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset: [Character] =
      Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
      var random: UInt8 = 0
      let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
      if status != errSecSuccess { fatalError("Unable to generate nonce.") }
      if random < charset.count {
        result.append(charset[Int(random % UInt8(charset.count))])
        remainingLength -= 1
      }
    }
    return result
  }

  private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
  }
}

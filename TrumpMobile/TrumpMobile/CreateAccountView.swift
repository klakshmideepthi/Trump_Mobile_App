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
  @State private var isCreating = false

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
          .accessibilityHidden(true)

        VStack(spacing: 16) {
          // Themed inputs for consistency and better readability
          TextField("Email address", text: $viewModel.email)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .textContentType(.emailAddress)
            .autocorrectionDisabled(true)
            .submitLabel(.next)
            .padding()
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(8)
            .accessibilityLabel("Email")

          SecureField("Password (min 8 characters)", text: $viewModel.password)
            .textContentType(.newPassword)
            .submitLabel(.next)
            .padding()
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(8)

          SecureField("Confirm password", text: $viewModel.confirmPassword)
            .textContentType(.newPassword)
            .submitLabel(.done)
            .padding()
            .background(Color.adaptiveSecondaryBackground)
            .cornerRadius(8)
            .accessibilityLabel("Confirm Password")

          if !passwordsMatch && !viewModel.confirmPassword.isEmpty {
            Text("Passwords don’t match.")
              .font(.footnote)
              .foregroundColor(.red)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          // Subtle guidance improves first-try success rates
          Text("Use at least 8 characters. Avoid using your name or email.")
            .font(.footnote)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)

        Button {
          createAccount()
        } label: {
          HStack {
            if isCreating { ProgressView().tint(.white) }
            Text("Create Account") // Title Case consistency
              .frame(maxWidth: .infinity)
          }
          .padding()
          .background(isFormValid ? Color.accentColor : Color.gray)
          .foregroundColor(.white)
          .cornerRadius(8)
        }
        .disabled(!isFormValid || isCreating)
        .padding(.horizontal)
        .accessibilityHint(!isFormValid ? "Enter a valid email and matching password" : "Create your account")

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
            Text("Sign up with Google") // Keep brand phrasing
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
          Button("Cancel") { dismiss() } // Keep simple, clear exit
        }
      }
      .alert(isPresented: $showError) {
        Alert(
          title: Text("Create Account"), // Consistent title casing
          message: Text(errorMessage),
          dismissButton: .default(Text("OK"))
        )
      }
    }
    .navigationBarBackButtonHidden()
  }

  private func createAccount() {
    guard isFormValid else {
      show(error: "Enter a valid email and a password with at least 8 characters.")
      return
    }

    // Create account in Firebase
    isCreating = true
    Auth.auth().createUser(withEmail: viewModel.email, password: viewModel.password) {
      result, error in
      isCreating = false
      if let error = error {
        show(error: "We couldn’t create your account. \(error.localizedDescription)")
        return
      }

      // Update user registration model
      if let user = result?.user {
        viewModel.userId = user.uid
        onAccountCreated?()
      } else {
        show(error: "We couldn’t create your account. Please try again.")
      }
    }
  }

  private var passwordsMatch: Bool {
    viewModel.password == viewModel.confirmPassword
  }

  private var isFormValid: Bool {
    let emailValid = viewModel.email.contains("@")
    let pwValid = viewModel.password.count >= 8
    return emailValid && pwValid && passwordsMatch
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


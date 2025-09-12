import SwiftUI
import AuthenticationServices
import CryptoKit

import FirebaseCore
import FirebaseAuth
import GoogleSignIn

struct LoginView: View {
    var onSignIn: (() -> Void)? = nil
    var onNewAccount: (() -> Void)? = nil

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showRegistration = false
    @State private var showError = false
    @State private var errorMessage = ""
    @StateObject private var viewModel = UserRegistrationViewModel()

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
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)

                    SecureField("Password", text: $password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal)

                Button {
                    signInWithEmail()
                } label: {
                    Text("Sign In")
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
                    signInWithGoogle()
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text("Sign in with Google")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                // Single, correct Apple button
                SignInWithAppleButton { request in
                    let nonce = randomNonceString()
                    currentNonce = nonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(nonce)
                } onCompletion: { result in
                    handleAppleSignIn(result: result)
                }
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .cornerRadius(8)
                .padding(.horizontal)

                HStack(spacing: 4) {
                    Text("New user?")
                    Button("Create an account") { showRegistration = true }
                }
                .padding(.top, 8)

                Spacer()
            }
            .navigationTitle("Sign In")
            .sheet(isPresented: $showRegistration) {
                CreateAccountView(viewModel: viewModel, onAccountCreated: {
                    showRegistration = false
                    onNewAccount?()
                })
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    // MARK: - Email / Password
    private func signInWithEmail() {
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                show(error: error.localizedDescription)
                return
            }
            onSignIn?()
        }
    }

    // MARK: - Google Sign-In (new API)
    private func signInWithGoogle() {
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
                show(error: error.localizedDescription)
                return
            }

            guard
                let idToken = signInResult?.user.idToken?.tokenString,
                let accessToken = signInResult?.user.accessToken.tokenString
            else {
                show(error: "Google authentication failed.")
                return
            }

            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    show(error: error.localizedDescription)
                } else {
                    onSignIn?()
                }
            }
        }
    }

    // MARK: - Apple Sign-In
    private func handleAppleSignIn(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard
                let appleIDCred = auth.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = appleIDCred.identityToken,
                let tokenString = String(data: identityToken, encoding: .utf8)
            else {
                show(error: "Apple Sign-In failed.")
                return
            }

            let nonce = currentNonce ?? ""
            // Use a compatible credential creation method 
            let credential = OAuthProvider.appleCredential(withIDToken: tokenString,
                                                          rawNonce: nonce,
                                                          fullName: appleIDCred.fullName)
            Auth.auth().signIn(with: credential) { _, error in
                if let error = error {
                    show(error: error.localizedDescription)
                } else {
                    onSignIn?()
                }
            }

        case .failure(let error):
            show(error: error.localizedDescription)
        }
    }

    // MARK: - Helpers
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


struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}

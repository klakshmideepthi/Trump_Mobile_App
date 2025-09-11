import SwiftUI
import FirebaseAuth

struct SplashView: View {
    @State private var isActive = false
    @State private var isSignedIn = false // Track sign-in state

    var body: some View {
        if isActive {
            ContentView()
            }
        else {
            VStack {
                Spacer()
                Image("Trump_Mobile_logo_gold")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280, height: 280)
                Spacer()
            }
            .background(Color.white)
            .ignoresSafeArea()
            .onAppear {
                // Check sign-in status using FirebaseAuth
                isSignedIn = checkIfUserIsSignedIn()
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }

    // Real authentication logic using FirebaseAuth
    func checkIfUserIsSignedIn() -> Bool {
        return Auth.auth().currentUser != nil
    }
}

import SwiftUI
import FirebaseAuth

struct SplashView: View {
    @State private var isActive = false
    @State private var isSignedIn = false
    @State private var authStateListener: AuthStateDidChangeListenerHandle?

    @EnvironmentObject private var navigationState: NavigationState
    
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
            .background(Color(.systemBackground))
            .ignoresSafeArea()
            .onAppear {
                // Set up auth state listener
                authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
                    isSignedIn = user != nil
                }
                
                // Delay splash screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
            .onDisappear {
                // Remove listener when view disappears
                if let handle = authStateListener {
                    Auth.auth().removeStateDidChangeListener(handle)
                }
            }
        }
    }
}

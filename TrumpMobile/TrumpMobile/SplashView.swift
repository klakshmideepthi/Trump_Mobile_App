import SwiftUI
import FirebaseAuth

struct SplashView: View {
    @State private var isActive = false
    @State private var isSignedIn = false // Track sign-in state
    @State private var authStateListener: AuthStateDidChangeListenerHandle?

    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        if isActive {
            ContentView()
                .onAppear {
                    print("DEBUG: ContentView appeared from SplashView")
                }
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
                print("DEBUG: SplashView appeared with navigationState")
                
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

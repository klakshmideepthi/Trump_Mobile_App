import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @State private var showStartOrder = false
    @State private var showProfileView = false
    var onStartOrder: (() -> Void)? = nil
    var onLogout: (() -> Void)? = nil
    @EnvironmentObject private var navigationState: NavigationState
    
    init(onStartOrder: (() -> Void)? = nil, onLogout: (() -> Void)? = nil) {
        print("DEBUG: HomeView initializing")
        self.onStartOrder = onStartOrder
        self.onLogout = onLogout
    }
    
    var body: some View {
        // Print statement moved inside onAppear
        NavigationView {
            ZStack {
                Color.trumpBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header with logo and profile button
                    HStack {
                        Image("Trump_Mobile_logo_gold")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 40)
                        
                        Spacer()
                        
                        Button(action: {
                            showProfileView = true
                        }) {
                            Image(systemName: "person.crop.circle")
                                .font(.system(size: 24))
                                .foregroundColor(Color.accentGold)
                        }
                        .sheet(isPresented: $showProfileView) {
                            ProfileView()
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Main content
                    Text("Welcome to")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.trumpText)
                    
                    Text("Trump™ Mobile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.trumpText)
                    
                    Text("Get started with Trump™ Mobile in\njust a few steps.")
                        .font(.title2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.trumpText)
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    Button(action: { 
                        if let onStartOrder = onStartOrder {
                            onStartOrder()
                        } else {
                            showStartOrder = true 
                        }
                    }) {
                        HStack {
                            Image(systemName: "cart.badge.plus")
                                .font(.headline)
                            Text("Start New Order")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentGold)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .onAppear {
                print("DEBUG: HomeView appeared")
            }
            .fullScreenCover(isPresented: $showStartOrder) {
                NavigationView {
                    StartOrderView(
                        onStart: { orderId in
                            showStartOrder = false
                            // Note: This will return to HomeView and then the parent ContentView
                            // will need to handle the actual navigation to the next step
                            if let onStartOrder = onStartOrder {
                                onStartOrder()
                            }
                        },
                        onLogout: onLogout
                    )
                    .navigationBarItems(trailing: Button(action: {
                        showStartOrder = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.trumpText)
                    })
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @State private var showStartOrder = false
    var onStartOrder: (() -> Void)? = nil
    var onLogout: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.trumpBackground.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image("Trump_Mobile_logo_gold")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .padding(.top, 20)
                    
                    Text("Trump™ Mobile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.trumpText)
                    
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
                    
                    if let onLogout = onLogout {
                        Button(action: onLogout) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Logout")
                            }
                            .foregroundColor(.red)
                        }
                        .padding(.bottom, 30)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $showStartOrder) {
                NavigationView {
                    StartOrderView(
                        onStart: {
                            showStartOrder = false
                            // Note: This will return to HomeView and then the parent ContentView
                            // will need to handle the actual navigation to the next step
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

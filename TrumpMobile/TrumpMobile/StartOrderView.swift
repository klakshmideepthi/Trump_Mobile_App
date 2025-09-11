import SwiftUI

struct StartOrderView: View {
    var onStart: () -> Void
    var onLogout: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 32) {
            Image("Trump_Mobile_logo_gold")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .padding(.top, 20)
            
            Text("Welcome to Trump™ Mobile")
                .font(.largeTitle)
                .bold()
                .padding(.top, 20)
                
            Text("Get started with Trump™ Mobile in just a few steps.")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
                
            Button(action: onStart) {
                HStack {
                    Image(systemName: "cart.badge.plus")
                        .font(.headline)
                    Text("Start New Order")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
            
            if let onLogout = onLogout {
                Button(action: onLogout) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
                .padding(.bottom, 30)
            }
        }
        .padding()
    }
}

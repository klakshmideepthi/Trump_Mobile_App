import SwiftUI

struct MessagesView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "message.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.blue.opacity(0.6))
                
                VStack(spacing: 12) {
                    Text("Messages Coming Soon")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Secure messaging feature in development")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                    }
                }
            }
        }
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView()
    }
}

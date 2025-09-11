import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                Image(systemName: "gearshape.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray.opacity(0.6))
                
                VStack(spacing: 12) {
                    Text("Settings Coming Soon")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Advanced settings panel in development")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

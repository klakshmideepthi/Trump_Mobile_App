import SwiftUI

extension Color {
    static let accentGold = Color("AccentColor")
    static let accentGold2 = Color("AccentColor2")
    // Use unique property names to avoid redeclaration
    static let trumpBackground = Color("BackgroundColor")
    static let trumpText = Color("TextColor")
    static let trumpSecondary = Color("SecondaryCustom") // Renamed to avoid conflict
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

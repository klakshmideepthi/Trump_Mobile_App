import SwiftUI

extension Color {
    static let accentGold = Color("AccentColor")
    static let accentGold2 = Color("AccentColor2")
    static let trumpPrimary = Color("TrumpPrimary")
    static let trumpBackground = Color("BackgroundColor")
    static let trumpText = Color("TextColor")
    static let trumpSecondary = Color("SecondaryCustom")
    
    // Adaptive colors for forms and UI elements
    static let adaptiveBackground = Color(.systemBackground)
    static let adaptiveSecondaryBackground = Color(.secondarySystemBackground)
    static let adaptiveTertiaryBackground = Color(.tertiarySystemBackground)
    static let adaptiveText = Color(.label)
    static let adaptiveSecondaryText = Color(.secondaryLabel)
    static let adaptiveBorder = Color(.systemGray4)
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

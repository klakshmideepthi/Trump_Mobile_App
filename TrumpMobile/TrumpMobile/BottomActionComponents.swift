import SwiftUI

// Shared primary gradient button used across screens
struct PrimaryGradientButton: View {
  let title: String
  let isDisabled: Bool
  let action: () -> Void

  init(
    title: String,
    isDisabled: Bool = false,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.isDisabled = isDisabled
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Text(title)
        .fontWeight(.semibold)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .foregroundColor(.white)
        .background(
          Group {
            if isDisabled {
              Color.gray.opacity(0.6)
            } else {
              LinearGradient(
                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                startPoint: .leading,
                endPoint: .trailing
              )
            }
          }
        )
        .cornerRadius(10)
    }
    .disabled(isDisabled)
  }
}

// Shared bottom action bar to standardize placement and styling
struct BottomActionBar<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    VStack(spacing: 0) {
      content
        .padding(.horizontal)
        .padding(.top, 10)
        .padding(.bottom, 16)
    }
    .background(
      Rectangle()
        .fill(Color.adaptiveBackground)
        .edgesIgnoringSafeArea(.bottom)
    )
  }
}



import SwiftUI

struct AppHeader<Content: View>: View {
  let content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    ZStack {
      Color.trumpBackground
        HStack {
          content
        }
        .padding(.horizontal, 20)
      }
      .frame(height: HeaderConstants.height)
    }
}

import SwiftUI

enum OrderStepLayout {
  static let horizontalPadding: CGFloat = 16
  static let verticalPadding: CGFloat = 16
  static let interSectionSpacing: CGFloat = 16
}

struct OrderStepHeader: View {
  let title: String
  let subtitle: String?

  init(_ title: String, subtitle: String? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  var body: some View {
    VStack(spacing: 8) {
      Text(title.uppercased())
        .font(.title2)
        .fontWeight(.bold)
        .multilineTextAlignment(.center)

      if let subtitle = subtitle, !subtitle.isEmpty {
        Text(subtitle.uppercased())
          .font(.subheadline)
          .foregroundColor(.primary)
          .multilineTextAlignment(.center)
          .lineSpacing(2)
      }
    }
    .frame(maxWidth: .infinity, alignment: .center)
  }
}

extension Text {
  func stepBodyCentered() -> some View {
    self
      .font(.body)
      .multilineTextAlignment(.center)
  }

  func stepCaptionCentered() -> some View {
    self
      .font(.caption)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
  }
}

extension View {
  func stepScreenPadding() -> some View {
    self
      .padding(.horizontal, OrderStepLayout.horizontalPadding)
      .padding(.top, OrderStepLayout.verticalPadding)
  }
}



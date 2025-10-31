import SwiftUI

struct PrivacyPolicyView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var scrollOffset: CGFloat = 0

  var body: some View {
    ZStack(alignment: .top) {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          // Top spacing and close
          HStack {
            Spacer()
            Button("Close") { dismiss() }
              .foregroundColor(.accentColor)
              .font(.body)
          }
          .padding(.horizontal, 20)
          .padding(.top, 20)

          // Header with scroll tracking
          VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Policy")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
              .background(
                GeometryReader { geo in
                  Color.clear
                    .onAppear { scrollOffset = geo.frame(in: .global).minY }
                    .onChange(of: geo.frame(in: .global).minY) { _, v in scrollOffset = v }
                }
              )

            Text("Last Updated: September 15, 2025")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.horizontal, 20)

          VStack(alignment: .leading, spacing: 15) {
            privacySection(
              title: "Information We Collect",
              content: """
                We collect information you provide directly to us, including:
                • Personal information (name, email, phone number)
                • Device information (IMEI, brand, model)
                • Billing and payment information
                • Service preferences and usage data
                """
            )

            privacySection(
              title: "How We Use Your Information",
              content: """
                We use your information to:
                • Provide and maintain our mobile services
                • Process transactions and manage your account
                • Send important service notifications
                • Improve our services and customer experience
                • Comply with legal obligations
                """
            )

            privacySection(
              title: "Information Sharing",
              content: """
                We do not sell, trade, or rent your personal information to third parties. We may share your information only:
                • With service providers who assist in our operations
                • When required by law or to protect our rights
                • With your explicit consent
                """
            )

            privacySection(
              title: "Data Security",
              content: """
                We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction. However, no method of transmission over the internet is 100% secure.
                """
            )

            privacySection(
              title: "Your Rights",
              content: """
                You have the right to:
                • Access your personal information
                • Correct inaccurate information
                • Request deletion of your information
                • Opt out of certain communications
                """
            )

            privacySection(
              title: "Contact Us",
              content: """
                If you have questions about this Privacy Policy, please contact us at:
                Email: privacy@telgoo5mobile.com
                Phone: 1-800-0000-000
                """
            )
          }
          .padding(.horizontal, 20)

          Spacer(minLength: 80)
        }
        .padding(.bottom, 30)
      }

      // Sticky Header
      if scrollOffset < -80 {
        VStack(spacing: 0) {
          HStack {
            Text("Privacy Policy")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Spacer()
            Button("Close") { dismiss() }
              .foregroundColor(.accentColor)
              .font(.body)
          }
          .padding()
          .background(Color(.systemBackground).opacity(0.95))
          .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: scrollOffset)
      }
    }
    .background(Color(UIColor.systemBackground))
    .navigationBarHidden(true)
  }

  private func privacySection(title: String, content: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text(content)
        .font(.body)
        .foregroundColor(.primary)
        .lineSpacing(4)
    }
  }
}

#Preview {
  PrivacyPolicyView()
}

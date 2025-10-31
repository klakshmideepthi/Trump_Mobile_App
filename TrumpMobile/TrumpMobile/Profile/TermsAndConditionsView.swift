import SwiftUI

struct TermsAndConditionsView: View {
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
            Text("Terms & Conditions")
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
            termsSection(
              title: "Acceptance of Terms",
              content: """
                By using Telgoo5 Mobile services, you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use our services.
                """
            )

            termsSection(
              title: "Service Description",
              content: """
                Telgoo5 Mobile provides wireless telecommunications services including voice, text, and data services. Service availability and quality may vary by location and device compatibility.
                """
            )

            termsSection(
              title: "Account Responsibilities",
              content: """
                You are responsible for:
                • Providing accurate account information
                • Maintaining the security of your account
                • All charges incurred on your account
                • Complying with applicable laws and regulations
                """
            )

            termsSection(
              title: "Payment and Billing",
              content: """
                • Monthly service charges are billed in advance
                • Usage charges are billed monthly in arrears
                • Late payments may result in service suspension
                • All charges are non-refundable unless required by law
                """
            )

            termsSection(
              title: "Service Limitations",
              content: """
                We reserve the right to:
                • Modify or discontinue services with notice
                • Suspend service for non-payment or misuse
                • Limit data usage during network congestion
                • Block harmful or illegal content
                """
            )

            termsSection(
              title: "Limitation of Liability",
              content: """
                Telgoo5 Mobile’s liability is limited to the monthly service charge. We are not liable for indirect, incidental, or consequential damages arising from service use or interruption.
                """
            )

            termsSection(
              title: "Termination",
              content: """
                Either party may terminate service with 30 days notice. We may terminate immediately for non-payment, misuse, or breach of these terms.
                """
            )

            termsSection(
              title: "Contact Information",
              content: """
                For questions about these terms, contact us at:
                Email: support@telgoo5mobile.com
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
            Text("Terms & Conditions")
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
    .background(Color.adaptiveBackground)
    .navigationBarHidden(true)
  }

  private func termsSection(title: String, content: String) -> some View {
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
  TermsAndConditionsView()
}

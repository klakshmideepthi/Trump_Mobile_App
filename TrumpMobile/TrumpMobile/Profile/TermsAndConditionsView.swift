import SwiftUI

struct TermsAndConditionsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 20) {
          Text("Terms & Conditions")
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .padding(.top, 60)

          VStack(alignment: .leading, spacing: 15) {
            Text("Last Updated: September 15, 2025")
              .font(.caption)
              .foregroundColor(.secondary)

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
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
      }
      .background(Color.adaptiveBackground)
      .navigationBarHidden(true)
      .overlay(
        HStack {
          Button(action: { dismiss() }) {
            HStack(spacing: 6) {
              Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
              Text("Back")
                .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.accentColor)
          }

          Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 10),
        alignment: .top
      )
    }
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

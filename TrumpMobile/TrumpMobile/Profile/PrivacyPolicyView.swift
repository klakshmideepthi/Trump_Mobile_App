import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .padding(.top, 60)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Last Updated: September 15, 2025")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
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
                            Email: privacy@trumpmobile.com
                            Phone: 1-800-TRUMP-MOBILE
                            """
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemBackground))
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

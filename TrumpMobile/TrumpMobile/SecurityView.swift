import SwiftUI

struct SecurityView: View {
    @State private var secureBootEnabled = true
    @State private var vpnProtectionEnabled = true
    @State private var safeBrowsingEnabled = true
    @State private var dataEncryptionEnabled = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Security Status Card
                    VStack {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "shield.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Security Status")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("All systems protected")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            
                            Spacer()
                        }
                        .padding()
                        
                        HStack {
                            Text("SECURE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            
                            Spacer()
                            
                            Text("Last scan: Just now")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .background(Color(red: 0.831, green: 0.659, blue: 0.267))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Protection Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Protection Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            ProtectionFeatureRow(
                                icon: "lock.fill",
                                title: "End-to-End Encryption",
                                subtitle: "Military-grade protection",
                                iconColor: Color(red: 0.831, green: 0.659, blue: 0.267),
                                isEnabled: true
                            )
                            
                            ProtectionFeatureRow(
                                icon: "touchid",
                                title: "Biometric Security",
                                subtitle: "Face ID & Touch ID",
                                iconColor: Color(red: 0.831, green: 0.659, blue: 0.267),
                                isEnabled: true
                            )
                            
                            ProtectionFeatureRow(
                                icon: "eye.fill",
                                title: "Privacy Shield",
                                subtitle: "Block tracking & ads",
                                iconColor: Color(red: 0.831, green: 0.659, blue: 0.267),
                                isEnabled: true
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Security Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Security Settings")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            SecuritySettingRow(
                                title: "Secure Boot",
                                subtitle: "Verify app integrity",
                                isEnabled: $secureBootEnabled
                            )
                            
                            SecuritySettingRow(
                                title: "VPN Protection",
                                subtitle: "Hide your location",
                                isEnabled: $vpnProtectionEnabled
                            )
                            
                            SecuritySettingRow(
                                title: "Safe Browsing",
                                subtitle: "Block malicious sites",
                                isEnabled: $safeBrowsingEnabled
                            )
                            
                            SecuritySettingRow(
                                title: "Data Encryption",
                                subtitle: "Encrypt stored data",
                                isEnabled: $dataEncryptionEnabled
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Threat Detection
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Threat Detection")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("CLEAN")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            ThreatDetectionRow(
                                title: "Malware Scan",
                                status: "Complete",
                                statusColor: .green,
                                icon: "checkmark.circle.fill"
                            )
                            
                            ThreatDetectionRow(
                                title: "Network Security",
                                status: "Secure",
                                statusColor: .green,
                                icon: "checkmark.circle.fill"
                            )
                            
                            ThreatDetectionRow(
                                title: "App Permissions",
                                status: "Review",
                                statusColor: .orange,
                                icon: "exclamationmark.triangle.fill"
                            )
                            
                            Button("Run Full Scan") {
                                // Perform security scan
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.831, green: 0.659, blue: 0.267))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .fontWeight(.semibold)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Security Tips
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Security Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            SecurityTipRow(title: "Enable Two-Factor Authentication")
                            SecurityTipRow(title: "Review App Permissions")
                            SecurityTipRow(title: "Update Security Settings")
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .navigationTitle("Security")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProtectionFeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
        }
    }
}

struct SecuritySettingRow: View {
    let title: String
    let subtitle: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
    }
}

struct ThreatDetectionRow: View {
    let title: String
    let status: String
    let statusColor: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(statusColor)
                .font(.system(size: 16))
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(status)
                .font(.caption)
                .foregroundColor(statusColor)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SecurityTipRow: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct SecurityView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityView()
    }
}

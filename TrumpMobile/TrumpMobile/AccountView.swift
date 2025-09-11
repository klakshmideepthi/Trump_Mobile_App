import SwiftUI

struct AccountView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            // Profile Avatar
                            Circle()
                                .fill(Color(red: 0.831, green: 0.659, blue: 0.267).opacity(0.2))
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Text("JP")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("John Patriot")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("john.patriot@trumpmobile.com")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text("Premium Member")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color(red: 0.831, green: 0.659, blue: 0.267).opacity(0.2))
                                    .cornerRadius(8)
                            }
                            
                            Spacer()
                        }
                        
                            Button("Edit Profile") {
                                // Edit profile action
                            }
                            .buttonStyle(GradientButtonStyle())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .fontWeight(.medium)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Account Stats
                    HStack(spacing: 15) {
                        AccountStatCard(icon: "calendar", value: "2", label: "Years Active", color: Color(red: 0.831, green: 0.659, blue: 0.267))
                        AccountStatCard(icon: "star.fill", value: "Gold", label: "Status Level", color: Color(red: 0.831, green: 0.659, blue: 0.267))
                    }
                    .padding(.horizontal)
                    
                    // Current Plan
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Current Plan")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Text("ACTIVE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(red: 0.831, green: 0.659, blue: 0.267).opacity(0.2))
                                .cornerRadius(8)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.gray)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Patriot Unlimited")
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text("Unlimited talk, text & data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "dollarsign.circle.fill")
                                    .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                                
                                Text("$75/month")
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("Next bill: Jan 15")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            
                                Button("Change Plan") {
                                    // Change plan action
                                }
                                .buttonStyle(GradientButtonStyle())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Usage Summary
                    VStack(alignment: .leading, spacing: 16) {
                        Text("This Month's Usage")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            UsageRow(
                                title: "Data Used",
                                used: "45.2 GB",
                                remaining: "Unlimited remaining",
                                progress: 0.65,
                                color: Color(red: 0.831, green: 0.659, blue: 0.267)
                            )
                            
                            UsageRow(
                                title: "Minutes Used",
                                used: "1,247 min",
                                remaining: "Unlimited remaining",
                                progress: 0.40,
                                color: Color(red: 0.831, green: 0.659, blue: 0.267)
                            )
                            
                            UsageRow(
                                title: "Text Messages",
                                used: "3,429",
                                remaining: "Unlimited remaining",
                                progress: 0.25,
                                color: Color(red: 0.831, green: 0.659, blue: 0.267)
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .shadow(radius: 2)
                        .padding(.horizontal)
                    }
                    
                    // Payment Method
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Payment Method")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Spacer()
                            
                            Button("Change") {
                                // Change payment method
                            }
                            .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                            .font(.subheadline)
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 12) {
                            Circle()
                                .fill(Color(red: 0.831, green: 0.659, blue: 0.267).opacity(0.2))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "creditcard.fill")
                                        .foregroundColor(Color(red: 0.831, green: 0.659, blue: 0.267))
                                )
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("•••• •••• •••• 4589")
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                Text("Expires 12/26")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                    
                    // Account Management
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Account Management")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            AccountActionRow(icon: "globe", title: "International Roaming")
                            AccountActionRow(icon: "person.2", title: "Family Plan")
                            AccountActionRow(icon: "creditcard", title: "Billing History")
                            AccountActionRow(icon: "phone", title: "Device Management")
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
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct AccountStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct UsageRow: View {
    let title: String
    let used: String
    let remaining: String
    let progress: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                
                Spacer()
                
                Text(used)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text(remaining)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AccountActionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.gray)
                .frame(width: 20)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        AccountView()
    }
}

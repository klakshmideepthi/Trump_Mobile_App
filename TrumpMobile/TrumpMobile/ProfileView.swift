import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userRegistrationViewModel: UserRegistrationViewModel
    @EnvironmentObject var contactInfoDetailViewModel: ContactInfoDetailViewModel
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: ContactInfoDetailView()) {
                        Label("Contact Information", systemImage: "person.fill")
                    }
                }
                
                Section(header: Text("Information")) {
                    Button(action: {
                        // About action
                    }) {
                        Label("About Trump™ Mobile", systemImage: "info.circle")
                    }
                    
                    Button(action: {
                        // Privacy Policy action
                    }) {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                    
                    Button(action: {
                        // Terms and Conditions action
                    }) {
                        Label("Terms and Conditions", systemImage: "doc.text")
                    }
                }
                
                #if DEBUG
                Section(header: Text("🔔 Notification Testing")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Firebase ID:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(notificationManager.firebaseInstallationID)
                        
                        Text("Permission: \(notificationManager.permissionGranted ? "✅ Granted" : "❌ Denied")")
                            .font(.caption)
                            .foregroundColor(notificationManager.permissionGranted ? .green : .red)
                            .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                    
                    Button(action: {
                        notificationManager.sendWelcomeNotification()
                    }) {
                        Label("Test Welcome Notification", systemImage: "bell")
                    }
                    
                    Button(action: {
                        notificationManager.sendOrderReminderNotification()
                    }) {
                        Label("Test Order Reminder", systemImage: "clock")
                    }
                    
                    Button(action: {
                        notificationManager.sendSimShippingNotification()
                    }) {
                        Label("Test SIM Shipping", systemImage: "box")
                    }
                    
                    Button(action: {
                        notificationManager.logUserEngagement()
                    }) {
                        Label("Log Engagement Event", systemImage: "chart.bar")
                    }
                }
                #endif
                
                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            userRegistrationViewModel.resetAllUserData()
                            userRegistrationViewModel.logout()
                            contactInfoDetailViewModel.reset()
                        } catch {
                            print("Error signing out: \(error.localizedDescription)")
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Logout")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

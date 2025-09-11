import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Account")) {
                    NavigationLink(destination: ContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {})) {
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
                
                Section {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
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

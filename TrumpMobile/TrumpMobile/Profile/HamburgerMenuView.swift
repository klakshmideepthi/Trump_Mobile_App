import SwiftUI
import FirebaseAuth

struct HamburgerMenuView: View {
    @Binding var isMenuOpen: Bool
    @State private var orders: [TrumpOrder] = []
    @State private var showLogoutAlert = false
    @EnvironmentObject var userRegistrationViewModel: UserRegistrationViewModel
    @EnvironmentObject var contactInfoDetailViewModel: ContactInfoDetailViewModel

    // Persist the user's color scheme preference
    @AppStorage("isDarkMode") private var isDarkMode: Bool = false
    
    var body: some View {
        ZStack {
            // Background overlay - covers entire screen
            if isMenuOpen {
                Color.black.opacity(0.3)
                    .ignoresSafeArea(.all)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isMenuOpen = false
                        }
                    }
            }
            
            // Menu content
            HStack {
                Spacer()
                
                if isMenuOpen {
                    VStack(alignment: .leading, spacing: 0) {
                        // Menu header
                        HStack {
                            Text("Menu")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isMenuOpen = false
                                }
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        Divider()
                        
                        // Menu items
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // Previous Orders
                                NavigationLink(destination: PreviousOrdersView(orders: orders)) {
                                    MenuItemView(icon: "bag", title: "Previous Orders")
                                }
                                
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                // Profile
                                NavigationLink(destination: ProfileView()) {
                                    MenuItemView(icon: "person", title: "Profile")
                                }
                                
                                Divider()
                                    .padding(.horizontal, 20)
                                
                                // Logout
                                Button {
                                    showLogoutAlert = true
                                } label: {
                                    MenuItemView(icon: "arrow.right.square", title: "Logout")
                                }

                                // Light/Dark mode toggle
                                HStack {
                                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(isDarkMode ? .yellow : .orange)
                                    Toggle(isDarkMode ? "Dark Mode" : "Light Mode", isOn: $isDarkMode)
                                        .toggleStyle(SwitchToggleStyle())
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.75)
                    .frame(maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(0)
                    .shadow(radius: 10)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        // Apply the color scheme based on the toggle
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .onAppear {
            loadOrders()
        }
        .alert("Log out", isPresented: $showLogoutAlert) {
            Button("Yes", role: .destructive) {
                logout()
            }
            Button("No", role: .cancel) {
                // Alert automatically dismisses
            }
        } message: {
            Text("Do you want to log out?")
        }
    }
    
    private func loadOrders() {
        // Load orders from Firebase
        FirebaseOrderManager.shared.fetchUserOrders { orders in
            DispatchQueue.main.async {
                self.orders = orders
            }
        }
    }
    
    private func logout() {
        // Implement logout functionality
        do {
            try Auth.auth().signOut()
            userRegistrationViewModel.resetAllUserData()
            userRegistrationViewModel.logout()
            contactInfoDetailViewModel.reset()
            withAnimation(.easeInOut(duration: 0.3)) {
                isMenuOpen = false
            }
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct MenuItemView: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }
}
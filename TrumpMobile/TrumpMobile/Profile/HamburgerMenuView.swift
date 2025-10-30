import FirebaseAuth
import SwiftUI

struct HamburgerMenuView: View {
  @Binding var isMenuOpen: Bool
  @State private var orders: [TrumpOrder] = []
  @State private var showLogoutAlert = false
  @EnvironmentObject var userRegistrationViewModel: UserRegistrationViewModel
  @EnvironmentObject var contactInfoDetailViewModel: ContactInfoDetailViewModel
  @EnvironmentObject var navigationState: NavigationState

  var body: some View {
    ZStack(alignment: .trailing) { // <- Align menu to the right
      if isMenuOpen {
        // Dimmed overlay
        Color.black.opacity(0.3)
          .ignoresSafeArea()
          .onTapGesture {
            withAnimation(.easeInOut(duration: 0.3)) {
              isMenuOpen = false
            }
          }

        // Menu panel
        VStack(spacing: 0) {
          // Header
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
          .padding(.top, 80)
          .padding(.bottom, 10)

          Divider()

          // Menu items
          ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
              // Contact Info
              Button {
                navigationState.showContactInfoDetail = true
                withAnimation { isMenuOpen = false }
              } label: {
                MenuItemView(icon: "person.circle", title: "Contact Information")
              }

              Divider().padding(.horizontal, 20)

              // Previous Orders
              Button {
                navigationState.showPreviousOrders = true
                withAnimation { isMenuOpen = false }
              } label: {
                MenuItemView(icon: "clock.arrow.circlepath", title: "Previous Orders")
              }

              Divider().padding(.horizontal, 20)

              // International Long Distance
              Button {
                navigationState.showInternationalLongDistance = true
                withAnimation { isMenuOpen = false }
              } label: {
                MenuItemView(icon: "globe", title: "International Long Distance")
              }

              Divider().padding(.horizontal, 20)
                .padding(.vertical, 10)

              // Privacy Policy
              Button {
                navigationState.showPrivacyPolicy = true
                withAnimation { isMenuOpen = false }
              } label: {
                MenuItemView(icon: "lock.shield", title: "Privacy Policy")
              }

              Divider().padding(.horizontal, 20)

              // Terms
              Button {
                navigationState.showTermsAndConditions = true
                withAnimation { isMenuOpen = false }
              } label: {
                MenuItemView(icon: "doc.text", title: "Terms & Conditions")
              }

              Divider().padding(.horizontal, 20)
                .padding(.vertical, 10)

              // Logout
              Button {
                showLogoutAlert = true
              } label: {
                MenuItemView(icon: "arrow.right.square",
                             title: "Logout",
                             isDestructive: true)
              }
            }
          }
        }
        .frame(width: UIScreen.main.bounds.width * 0.75)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20) // <- Rounded corner for a cleaner slide-in
        .shadow(radius: 10)
        .ignoresSafeArea()
        .transition(.move(edge: .trailing)) // <- Slides from the right
      }
    }
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
    print("🔄 HamburgerMenuView logout called")

    do {
      try Auth.auth().signOut()
      print("✅ User signed out successfully")

      // Clear any stored order data
      UserDefaults.standard.removeObject(forKey: "currentOrderId")

      // Reset view models
      userRegistrationViewModel.reset()
      contactInfoDetailViewModel.reset()

      // Reset navigation state
      navigationState.reset()

      // Close menu
      withAnimation(.easeInOut(duration: 0.3)) {
        isMenuOpen = false
      }

      // The auth state change will be automatically detected by SplashView
      // and navigate back to splash/login screen

    } catch let signOutError as NSError {
      print("❌ Error signing out: \(signOutError)")
      // Still reset local data even if Firebase signout fails
      userRegistrationViewModel.reset()
      contactInfoDetailViewModel.reset()
      navigationState.reset()
      UserDefaults.standard.removeObject(forKey: "currentOrderId")

      // Close menu
      withAnimation(.easeInOut(duration: 0.3)) {
        isMenuOpen = false
      }
    }
  }
}

struct MenuItemView: View {
  let icon: String
  let title: String
  var isDestructive: Bool = false

  var body: some View {
    HStack(spacing: 15) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(isDestructive ? .red : .accentColor)
        .frame(width: 24, height: 24)

      Text(title)
        .font(.body)
        .foregroundColor(isDestructive ? .red : .primary)

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

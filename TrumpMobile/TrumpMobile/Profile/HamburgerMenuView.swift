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
                // Contact Information (Direct access)
                Button {
                  navigationState.showContactInfoDetail = true
                  withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                  }
                } label: {
                  MenuItemView(icon: "person.circle", title: "Contact Information")
                }

                Divider()
                  .padding(.horizontal, 20)

                // Previous Orders
                Button {
                  navigationState.showPreviousOrders = true
                  withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                  }
                } label: {
                  MenuItemView(icon: "clock.arrow.circlepath", title: "Previous Orders")
                }

                Divider()
                  .padding(.horizontal, 20)

                // International Long Distance
                Button {
                  navigationState.showInternationalLongDistance = true
                  withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                  }
                } label: {
                  MenuItemView(icon: "globe", title: "International Long Distance")
                }

                // Divider for legal section
                Divider()
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)

                // Privacy Policy
                Button {
                  navigationState.showPrivacyPolicy = true
                  withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                  }
                } label: {
                  MenuItemView(icon: "lock.shield", title: "Privacy Policy")
                }

                Divider()
                  .padding(.horizontal, 20)

                // Terms and Conditions
                Button {
                  navigationState.showTermsAndConditions = true
                  withAnimation(.easeInOut(duration: 0.3)) {
                    isMenuOpen = false
                  }
                } label: {
                  MenuItemView(icon: "doc.text", title: "Terms & Conditions")
                }

                // Divider before logout
                Divider()
                  .padding(.horizontal, 20)
                  .padding(.vertical, 10)

                // Logout
                Button {
                  showLogoutAlert = true
                } label: {
                  MenuItemView(icon: "arrow.right.square", title: "Logout", isDestructive: true)
                }
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

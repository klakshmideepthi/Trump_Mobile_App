import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct FeatureRow: View {
  let icon: String
  let text: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .frame(width: 24, height: 24)
        .foregroundStyle(
          LinearGradient(
            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
            startPoint: .leading,
            endPoint: .trailing
          )
        )

      Text(text)
        .font(.body)
        .foregroundColor(.trumpText)
    }
  }
}

struct StartOrderView: View {
  var onStart: (String?) -> Void
  var onLogout: (() -> Void)? = nil

  @State private var isLoading = false
  @State private var errorMessage: String? = nil
  @State private var showInternationalDetails = false
  @State private var isMenuOpen = false
  @EnvironmentObject private var navigationState: NavigationState

  var body: some View {
    return ZStack {
      Color.trumpBackground.ignoresSafeArea()
      VStack(spacing: 0) {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            // Header with logo and hamburger menu
            HStack {
              Image("Trump_Mobile_logo_gold")
                .resizable()
                .scaledToFit()
                .frame(height: 80)
              Spacer()
              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  isMenuOpen = true
                }
              }) {
                Image(systemName: "line.3.horizontal")
                  .font(.system(size: 30))
                  .foregroundStyle(
                    LinearGradient(
                      gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
              }
            }
            .padding(.horizontal)
            .padding(.top, 10)
            // Header section with plan badge
            GeometryReader { geometry in
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("ALL-AMERICAN")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.trumpText)
                  Text("PERFORMANCE.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.trumpText)
                  Text("EVERYDAY PRICE.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.trumpText)
                }
                .frame(width: geometry.size.width * 0.7, alignment: .leading)

                ZStack {
                  Circle()
                    .fill(Color.primary.opacity(0.9))
                    .frame(width: 100, height: 100)
                  VStack(spacing: 0) {
                    Text("The")
                      .font(.system(size: 16, weight: .medium))
                      .foregroundColor(Color(.systemBackground))
                    Text("47")
                      .font(.system(size: 36, weight: .bold))
                      .foregroundStyle(
                        LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                      )
                    Text("plan")
                      .font(.system(size: 16, weight: .medium))
                      .foregroundColor(Color(.systemBackground))
                  }
                }
                .frame(width: geometry.size.width * 0.3, alignment: .trailing)
              }
            }
            .frame(height: 150)  // Adjust as needed
            .padding(.top, 20)
            // Price section
            Text("$47.45/MONTH.")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundStyle(
                LinearGradient(
                  gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .padding(.bottom, 10)
            // Features section
            VStack(alignment: .leading, spacing: 18) {
              FeatureRow(icon: "message.and.waveform.fill", text: "Unlimited Talk, Text & Data")
              FeatureRow(icon: "simcard.fill", text: "Free SIM Kit + Shipping")
              FeatureRow(icon: "doc.text.fill", text: "No Contract – Cancel Anytime")
              FeatureRow(icon: "iphone", text: "Bring Your Own Phone")
              HStack(alignment: .top, spacing: 12) {
                Image(systemName: "globe")
                  .frame(width: 24, height: 24)
                  .foregroundStyle(
                    LinearGradient(
                      gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                      startPoint: .leading,
                      endPoint: .trailing
                    )
                  )
                VStack(alignment: .leading) {
                  Text("International Calling to 100 destinations")
                    .foregroundColor(.trumpText)
                  Button(action: {
                    showInternationalDetails.toggle()
                  }) {
                    Text("see details here")
                      .foregroundStyle(
                        LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                      )
                      .underline()
                  }
                }
              }
              FeatureRow(icon: "creditcard.fill", text: "No Credit Check")
            }
            .padding(.bottom, 20)
            if let error = errorMessage {
              Text(error)
                .foregroundColor(.red)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            Spacer(minLength: 80)  // Add space for the button at the bottom
          }
          .padding(.horizontal)
        }
        // Fixed bottom button
        VStack {
          Button(action: createNewOrder) {
            Text("Enroll in Telgoo5 Mobile Now")
              .font(.headline)
              .fontWeight(.bold)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                LinearGradient(
                  gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .foregroundColor(.white)
              .cornerRadius(25)
          }
          .padding(.horizontal)
          .padding(.bottom, 20)
          .disabled(isLoading)
        }
        .background(Color.trumpBackground.ignoresSafeArea(edges: .bottom))
      }
      .ignoresSafeArea(.keyboard)
      .sheet(isPresented: $showInternationalDetails) {
        NavigationView {
          InternationalLongDistanceView()
        }
      }
      .sheet(isPresented: $navigationState.showPreviousOrders) {
        NavigationView {
          PreviousOrdersView(orders: [])
        }
      }
      .sheet(isPresented: $navigationState.showContactInfoDetail) {
        NavigationView {
          ContactInfoDetailView()
        }
      }
      .sheet(isPresented: $navigationState.showInternationalLongDistance) {
        NavigationView {
          InternationalLongDistanceView()
        }
      }
      .sheet(isPresented: $navigationState.showPrivacyPolicy) {
        PrivacyPolicyView()
      }
      .sheet(isPresented: $navigationState.showTermsAndConditions) {
        TermsAndConditionsView()
      }

      // Hamburger menu overlay
      HamburgerMenuView(isMenuOpen: $isMenuOpen)

      // Loading overlay (no dimming)
      if isLoading {
        VStack {
          Spacer()
          HStack {
            Spacer()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle())
              .scaleEffect(2.0)
            Spacer()
          }
          Spacer()
        }
        .transition(.opacity)
        .zIndex(1)
      }
    }

    func createNewOrder() {
      guard let userId = Auth.auth().currentUser?.uid else {
        errorMessage = "Please sign in to create an order"
        return
      }

      isLoading = true
      errorMessage = nil

      // Step 1: Create a new order document
      FirebaseManager.shared.createNewOrder(userId: userId) { orderId, error in
        if let error = error {
          DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to create order: \(error.localizedDescription)"
          }
          return
        }

        guard let orderId = orderId else {
          DispatchQueue.main.async {
            isLoading = false
            errorMessage = "Failed to get order ID"
          }
          return
        }

        // Track completion for copying operations
        let dispatchGroup = DispatchGroup()

        // Step 2: Copy contact info to the order (for convenience)
        dispatchGroup.enter()
        FirebaseManager.shared.copyContactInfoToOrder(userId: userId, orderId: orderId) {
          success, error in
          if let error = error {
            print("Warning: Failed to copy contact info: \(error.localizedDescription)")
          }
          dispatchGroup.leave()
        }

        // Step 3: Copy shipping address to the order (for convenience)
        dispatchGroup.enter()
        FirebaseManager.shared.copyShippingAddressToOrder(userId: userId, orderId: orderId) {
          success, error in
          if let error = error {
            print("Warning: Failed to copy shipping address: \(error.localizedDescription)")
          }
          dispatchGroup.leave()
        }

        // When all copy operations complete
        dispatchGroup.notify(queue: .main) {
          isLoading = false
          // Navigate to next screen with the order ID
          // This will trigger a fresh view model that loads only basic user info
          onStart(orderId)
        }
      }
    }
  }

  struct StartOrderView_Previews: PreviewProvider {
    static var previews: some View {
      StartOrderView(onStart: { _ in })
    }
  }
}

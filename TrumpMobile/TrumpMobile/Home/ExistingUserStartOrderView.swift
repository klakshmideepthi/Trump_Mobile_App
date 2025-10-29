import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ExistingUserStartOrderView: View {
  var previousOrders: [TrumpOrder] = []
  var onStart: ((String?) -> Void)?
  var onLogout: (() -> Void)?

  @State private var isMenuOpen = false
  @State private var loadedOrders: [TrumpOrder] = []
  @State private var incompleteOrders: [IncompleteOrder] = []
  @State private var isLoading = true
  @State private var isCreatingOrder = false
  @State private var errorMessage: String?
  @EnvironmentObject private var navigationState: NavigationState

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()

      VStack(spacing: 0) {
        HStack {
          Image("Trump_Mobile_logo_gold")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 80)

          Spacer()

          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              isMenuOpen.toggle()
            }
          }) {
            Image(systemName: "line.horizontal.3")
              .font(.title2)
              .foregroundColor(.primary)
          }
        }
        .padding(.horizontal)
        .padding(.top, 10)

        ScrollView {
          VStack(spacing: 24) {
            // Welcome Section
            VStack(spacing: 12) {
              Text("Welcome back!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text("Here's your dashboard.")
                .font(.headline)
                .foregroundColor(.secondary)
            }
            .padding(.top, 20)

            // Incomplete Tasks Section (Priority display)
            if !incompleteOrders.isEmpty {
              incompleteTasksSection
            }

            // Previous Orders Section
            let ordersToShow = !previousOrders.isEmpty ? previousOrders : loadedOrders

            if isLoading {
              ProgressView("Loading your orders...")
                .foregroundColor(.primary)
            } else if !ordersToShow.isEmpty {
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Text("Recent Orders")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                  Spacer()

                  Text("\(ordersToShow.count) total")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                  ForEach(ordersToShow.prefix(3), id: \.id) { order in
                    NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                      OrderCardView(order: order)
                    }
                    .buttonStyle(PlainButtonStyle())
                  }
                }

                if ordersToShow.count > 3 {
                  HStack {
                    Image(systemName: "eye")
                      .foregroundColor(.accentColor)
                    Text("View all orders in Profile")
                      .font(.caption)
                      .foregroundColor(.secondary)
                    Spacer()
                  }
                  .padding(.top, 8)
                }
              }
              .padding()
              .background(Color(.systemGray6))
              .cornerRadius(12)
            } else {
              VStack(spacing: 16) {
                Image(systemName: "bag")
                  .font(.system(size: 50))
                  .foregroundColor(.secondary)

                Text("No previous orders found.")
                  .font(.subheadline)
                  .foregroundColor(.secondary)

                Text("Start your first Telgoo5 Mobile order below!")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .padding(30)
              .background(Color(.systemGray6))
              .cornerRadius(12)
            }

            Spacer(minLength: 100)  // Space for bottom button
          }
          .padding(.horizontal)
        }

        // Fixed bottom button
        VStack {
          // Error message if order creation fails
          if let errorMessage = errorMessage {
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.red)
              .padding(.horizontal)
              .padding(.top, 8)
          }

          Button(action: {
            createNewOrderAndStart()
          }) {
            HStack {
              if isCreatingOrder {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.8)
                Text("Creating Order...")
              } else {
                Text("Start a New Order")
              }
            }
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
            .opacity(isCreatingOrder ? 0.7 : 1.0)
          }
          .padding(.horizontal)
          .padding(.bottom, 20)
          .disabled(isCreatingOrder)
        }
      }
      .background(Color.trumpBackground.ignoresSafeArea(edges: .bottom))

      // Hamburger menu overlay
      HamburgerMenuView(isMenuOpen: $isMenuOpen)
    }
    .sheet(isPresented: $navigationState.showPreviousOrders) {
      NavigationView {
        PreviousOrdersView(orders: previousOrders.isEmpty ? loadedOrders : previousOrders)
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
    .onAppear {
      print("DEBUG: ExistingUserStartOrderView - previousOrders count: \(previousOrders.count)")

      // If no orders were passed, try to load them directly
      if previousOrders.isEmpty {
        loadOrdersDirectly()
      } else {
        isLoading = false
      }

      // Load incomplete orders
      loadIncompleteOrders()
    }
  }

  private var incompleteTasksSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Complete Your Setup")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.primary)

      Text("You have orders that need completion to activate your SIM:")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)

      // Horizontal ScrollView for multiple incomplete orders
      if incompleteOrders.count > 1 {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            ForEach(incompleteOrders, id: \.id) { order in
              IncompleteOrderCard(
                order: order,
                onComplete: { orderId in
                  completeOrderSetup(orderId: orderId)
                }
              )
              .frame(width: 300)  // Fixed width for horizontal scrolling
            }
          }
          .padding(.horizontal, 4)  // Small padding for scroll effect
        }
      } else {
        // Single order - no horizontal scroll needed
        ForEach(incompleteOrders, id: \.id) { order in
          IncompleteOrderCard(
            order: order,
            onComplete: { orderId in
              completeOrderSetup(orderId: orderId)
            }
          )
        }
      }

      // Page indicator for multiple orders
      if incompleteOrders.count > 1 {
        HStack {
          Spacer()
          HStack(spacing: 8) {
            ForEach(0..<incompleteOrders.count, id: \.self) { index in
              Circle()
                .fill(Color.accentGold.opacity(0.3))
                .frame(width: 8, height: 8)
            }
          }
          Spacer()
        }
        .padding(.top, 8)
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color.accentGold.opacity(0.1))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.accentGold.opacity(0.3), lineWidth: 1)
    )
  }

  private func loadIncompleteOrders() {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("DEBUG: No authenticated user for loading incomplete orders")
      return
    }

    let db = Firestore.firestore()
    db.collection("users").document(userId).collection("orders")
      .whereField("portInSkipped", isEqualTo: true)
      .getDocuments { snapshot, error in
        DispatchQueue.main.async {
          if let error = error {
            print("❌ Error fetching incomplete orders: \(error.localizedDescription)")
            return
          }

          let orders =
            snapshot?.documents.compactMap { doc -> IncompleteOrder? in
              let data = doc.data()
              return IncompleteOrder(
                id: doc.documentID,
                phoneNumber: data["selectedPhoneNumber"] as? String ?? "Unknown",
                simType: data["simType"] as? String ?? "Physical SIM",
                deviceBrand: data["deviceBrand"] as? String ?? "Unknown",
                deviceModel: data["deviceModel"] as? String ?? "Unknown",
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                missingTasks: self.determineMissingTasks(from: data)
              )
            } ?? []

          self.incompleteOrders = orders
          print("DEBUG: Found \(orders.count) incomplete orders")
        }
      }
  }

  private func determineMissingTasks(from data: [String: Any]) -> [String] {
    var tasks: [String] = []

    // Check if port-in information is missing
    if (data["portInAccountNumber"] as? String ?? "").isEmpty
      || (data["portInPin"] as? String ?? "").isEmpty
      || (data["portInCurrentCarrier"] as? String ?? "").isEmpty
      || (data["portInAccountHolderName"] as? String ?? "").isEmpty
    {
      tasks.append("Complete number porting information")
    }

    // Check if billing information is missing
    if (data["creditCardNumber"] as? String ?? "").isEmpty
      || (data["billingDetails"] as? String ?? "").isEmpty
    {
      tasks.append("Complete billing information")
    }

    // Check if contact information is complete
    if (data["firstName"] as? String ?? "").isEmpty || (data["lastName"] as? String ?? "").isEmpty
      || (data["street"] as? String ?? "").isEmpty
    {
      tasks.append("Complete contact and shipping information")
    }

    return tasks.isEmpty ? ["Complete remaining order steps"] : tasks
  }

  private func completeOrderSetup(orderId: String) {
    print("DEBUG: Completing order setup for orderId: \(orderId)")
    // Navigate to the order flow with the specific order ID
    onStart?(orderId)
  }

  private func createNewOrderAndStart() {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("❌ No authenticated user")
      errorMessage = "Authentication error. Please log in again."
      return
    }

    // Clear any previous error message
    errorMessage = nil
    isCreatingOrder = true

    print("🔄 Creating new order for userId: \(userId)")

    // Create order first, then start the flow
    FirebaseManager.shared.createNewOrder(userId: userId) { orderId, error in
      DispatchQueue.main.async {
        self.isCreatingOrder = false

        if let error = error {
          print("❌ Failed to create order: \(error.localizedDescription)")
          self.errorMessage = "Failed to create order. Please try again."
          return
        }

        guard let orderId = orderId else {
          print("❌ No order ID returned")
          self.errorMessage = "Order creation failed. Please try again."
          return
        }

        print("✅ Order created with ID: \(orderId)")
        print("🚀 Starting order flow with orderId: \(orderId)")

        // Store order ID in UserDefaults for persistence
        UserDefaults.standard.set(orderId, forKey: "currentOrderId")

        // Now start the order flow with the order ID
        self.onStart?(orderId)
      }
    }
  }

  private func loadOrdersDirectly() {
    guard let userId = Auth.auth().currentUser?.uid else {
      isLoading = false
      return
    }

    FirebaseOrderManager.shared.fetchUserOrders { orders in
      DispatchQueue.main.async {
        print("DEBUG: ExistingUserStartOrderView - Loaded \(orders.count) orders directly")
        self.loadedOrders = orders
        self.isLoading = false
      }
    }
  }
}

// MARK: - Supporting Data Structures
struct IncompleteOrder {
  let id: String
  let phoneNumber: String
  let simType: String
  let deviceBrand: String
  let deviceModel: String
  let createdAt: Date
  let missingTasks: [String]
}

// MARK: - UI Components
struct IncompleteOrderCard: View {
  let order: IncompleteOrder
  let onComplete: (String) -> Void

  private var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Order header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Order #\(String(order.id.prefix(8)))")
            .font(.headline)
            .foregroundColor(.primary)
            .lineLimit(1)

          Text("Started: \(dateFormatter.string(from: order.createdAt))")
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }

        Spacer()

        // Status badge
        Text("Incomplete")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.orange.opacity(0.2))
          .foregroundColor(.orange)
          .cornerRadius(8)
      }

      // Order details
      VStack(alignment: .leading, spacing: 6) {
        if !order.phoneNumber.isEmpty && order.phoneNumber != "Unknown" {
          HStack {
            Image(systemName: "phone.fill")
              .foregroundColor(.accentGold)
              .frame(width: 16)
            Text("Number: \(order.phoneNumber)")
              .font(.subheadline)
              .foregroundColor(.primary)
              .lineLimit(1)
          }
        }

        HStack {
          Image(systemName: "sim.fill")
            .foregroundColor(.accentGold)
            .frame(width: 16)
          Text("SIM Type: \(order.simType)")
            .font(.subheadline)
            .foregroundColor(.primary)
            .lineLimit(1)
        }

        if order.deviceBrand != "Unknown" {
          HStack {
            Image(systemName: "iphone")
              .foregroundColor(.accentGold)
              .frame(width: 16)
            Text("Device: \(order.deviceBrand) \(order.deviceModel)")
              .font(.subheadline)
              .foregroundColor(.primary)
              .lineLimit(1)
          }
        }
      }

      // Missing tasks - limited height for horizontal scroll
      if !order.missingTasks.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("Tasks to Complete:")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          // Show only first 2 tasks in horizontal scroll to maintain card height
          ForEach(Array(order.missingTasks.prefix(2).enumerated()), id: \.offset) { index, task in
            HStack(alignment: .top, spacing: 8) {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
                .font(.caption)
                .padding(.top, 2)

              Text(task)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)
            }
          }

          // Show "+X more" if there are additional tasks
          if order.missingTasks.count > 2 {
            Text(
              "+\(order.missingTasks.count - 2) more task\(order.missingTasks.count - 2 == 1 ? "" : "s")"
            )
            .font(.caption2)
            .foregroundColor(.secondary)
            .italic()
            .padding(.leading, 24)
          }
        }
        .padding(.top, 4)
      }

      Spacer()  // Push buttons to bottom

      // Action buttons
      VStack(spacing: 8) {
        // View Details button
        NavigationLink(destination: OrderDetailView(orderId: order.id)) {
          HStack {
            Image(systemName: "info.circle")
            Text("View Details")
              .fontWeight(.medium)
          }
          .foregroundColor(.accentGold)
          .padding(.vertical, 10)
          .frame(maxWidth: .infinity)
          .background(Color.accentGold.opacity(0.1))
          .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())

        // Complete setup button
        Button(action: {
          onComplete(order.id)
        }) {
          HStack {
            Image(systemName: "checkmark.circle.fill")
            Text("Complete Setup")
              .fontWeight(.medium)
          }
          .foregroundColor(.white)
          .padding(.vertical, 12)
          .frame(maxWidth: .infinity)
          .background(
            LinearGradient(
              gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
              startPoint: .leading,
              endPoint: .trailing
            )
          )
          .cornerRadius(10)
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 360)  // Adjusted height for two buttons
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
}

struct OrderCardView: View {
  let order: TrumpOrder

  var body: some View {
    HStack {
      // Status indicator
      Circle()
        .fill(statusColor)
        .frame(width: 12, height: 12)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Order #\(order.id.prefix(8))")
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.primary)

          Spacer()

          Text(order.orderDate, style: .date)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        HStack {
          Text(order.status.displayName)
            .font(.caption)
            .foregroundColor(statusColor)

          Spacer()

          if let phoneNumber = order.phoneNumber {
            Text(phoneNumber)
              .font(.caption)
              .foregroundColor(.secondary)
          }
        }
      }

      // Add arrow to indicate it's tappable
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
        .opacity(0.7)
    }
    .padding(12)
    .background(Color(.systemGray5).opacity(0.3))
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
  }

  private var statusColor: Color {
    switch order.status {
    case .pending:
      return .orange
    case .completed:
      return .green
    case .cancelled:
      return .red
    }
  }
}

#Preview {
  ExistingUserStartOrderView(previousOrders: [])
    .environmentObject(UserRegistrationViewModel())
}

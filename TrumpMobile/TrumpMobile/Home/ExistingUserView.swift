import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct ExistingUserView: View {
  var previousOrders: [TrumpOrder] = []
  var onLogout: (() -> Void)?

  @State private var isMenuOpen = false
  @State private var loadedOrders: [TrumpOrder] = []
  @State private var incompleteOrders: [IncompleteOrder] = []
  @State private var isLoading = true
  @State private var errorMessage: String?
  @EnvironmentObject private var navigationState: NavigationState
  @State private var carouselIndex: Int = 0
  @State private var selectedPlan: Plan? = nil
  @State private var planNavIsActive = false
  private let plans = PlansData.allPlans

  var body: some View {
    NavigationView {
      ZStack {
        Color.trumpBackground.ignoresSafeArea()

        VStack(spacing: 0) {
          // HEADER
          AppHeader {
            Image("Trump_Mobile_logo_gold")
              .resizable()
              .aspectRatio(80.0 / 23.0, contentMode: .fit)
              .frame(height: 25)
              .clipped()

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

          // MAIN CONTENT
          ScrollView {
            VStack(spacing: 24) {
              // Welcome Section
              VStack(spacing: 12) {
                Text("Welcome back!")
                  .font(.largeTitle)
                  .fontWeight(.bold)
                  .foregroundColor(.primary)

                Text("Here’s your dashboard.")
                  .font(.headline)
                  .foregroundColor(.secondary)
              }
              .padding(.top, 20)

              // Plans Carousel
              VStack(spacing: 8) {
                Text("Available Plans")
                  .font(.headline)
                  .padding(.top, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                  PlanCarousel(plans: plans, selectedPlan: $selectedPlan, planNavIsActive: $planNavIsActive)
                }

                // Carousel dots
                HStack(spacing: 8) {
                  ForEach(0..<plans.count, id: \.self) { idx in
                    Circle()
                      .fill(idx == carouselIndex ? Color.accentColor : Color.secondary.opacity(0.2))
                      .frame(width: 8, height: 8)
                  }
                }
              }

              // Incomplete Orders Section
              if !incompleteOrders.isEmpty {
                incompleteTasksSection
              }

              // Previous Orders Section
              let ordersToShow = !previousOrders.isEmpty ? previousOrders : loadedOrders

              if isLoading {
                ProgressView("Loading your orders...")
                  .foregroundColor(.primary)
              } else if !ordersToShow.isEmpty {
                recentOrdersSection(orders: ordersToShow)
              } else {
                noOrdersSection
              }

              Spacer(minLength: 20)
            }
            .padding(.horizontal)
          }
        }
        .background(Color.trumpBackground.ignoresSafeArea(edges: .bottom))

        // Hamburger Menu
        HamburgerMenuView(isMenuOpen: $isMenuOpen)
      }
    }
    // SHEETS
    .sheet(isPresented: $navigationState.showPreviousOrders) {
      NavigationView {
        PreviousOrdersView(orders: previousOrders.isEmpty ? loadedOrders : previousOrders)
      }
    }
    .sheet(isPresented: $navigationState.showContactInfoDetail) {
      NavigationView { ContactInfoDetailView() }
    }
    .sheet(isPresented: $navigationState.showInternationalLongDistance) {
      NavigationView { InternationalLongDistanceView() }
    }
    .sheet(isPresented: $navigationState.showPrivacyPolicy) {
      PrivacyPolicyView()
    }
    .sheet(isPresented: $navigationState.showTermsAndConditions) {
      TermsAndConditionsView()
    }
    // LOAD DATA
    .onAppear {
      if previousOrders.isEmpty {
        loadOrdersDirectly()
      } else {
        isLoading = false
      }
      loadIncompleteOrders()
    }
  }

  // MARK: - Sections

  private func recentOrdersSection(orders: [TrumpOrder]) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text("Recent Orders")
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.primary)

        Spacer()

        Text("\(orders.count) total")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      VStack(spacing: 12) {
        ForEach(orders.prefix(3), id: \.id) { order in
          NavigationLink(destination: OrderDetailView(orderId: order.id)) {
            OrderCardView(order: order)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }

      if orders.count > 3 {
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
  }

  private var noOrdersSection: some View {
    VStack(spacing: 16) {
      Image(systemName: "bag")
        .font(.system(size: 50))
        .foregroundColor(.secondary)

      Text("No previous orders found.")
        .font(.subheadline)
        .foregroundColor(.secondary)

      Text("Start your first TelcoFi Mobile order below!")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(30)
    .background(Color.adaptiveSecondaryBackground)
    .cornerRadius(12)
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

      if incompleteOrders.count > 1 {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 16) {
            ForEach(incompleteOrders, id: \.id) { order in
              IncompleteOrderCard(order: order, onComplete: { orderId in
                completeOrderSetup(orderId: orderId)
              })
              .frame(width: 300)
            }
          }
          .padding(.horizontal, 4)
        }
      } else {
        ForEach(incompleteOrders, id: \.id) { order in
          IncompleteOrderCard(order: order, onComplete: { orderId in
            completeOrderSetup(orderId: orderId)
          })
        }
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

  // MARK: - Firestore Logic

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

          let orders = snapshot?.documents.compactMap { doc -> IncompleteOrder? in
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

    if (data["portInAccountNumber"] as? String ?? "").isEmpty
      || (data["portInPin"] as? String ?? "").isEmpty
      || (data["portInCurrentCarrier"] as? String ?? "").isEmpty
      || (data["portInAccountHolderName"] as? String ?? "").isEmpty {
      tasks.append("Complete number porting information")
    }

    if (data["creditCardNumber"] as? String ?? "").isEmpty
      || (data["billingDetails"] as? String ?? "").isEmpty {
      tasks.append("Complete billing information")
    }

    if (data["firstName"] as? String ?? "").isEmpty
      || (data["lastName"] as? String ?? "").isEmpty
      || (data["street"] as? String ?? "").isEmpty {
      tasks.append("Complete contact and shipping information")
    }

    return tasks.isEmpty ? ["Complete remaining order steps"] : tasks
  }

  private func completeOrderSetup(orderId: String) {
    // Navigation or order flow logic can be handled via NavigationState or other means
  }

  private func loadOrdersDirectly() {
    guard Auth.auth().currentUser?.uid != nil else {
      isLoading = false
      return
    }

    FirebaseOrderManager.shared.fetchUserOrders { orders in
      DispatchQueue.main.async {
        print("DEBUG: Loaded \(orders.count) orders directly")
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
    return formatter
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("Order #\(String(order.id.prefix(8)))")
            .font(.headline)
            .foregroundColor(.primary)
          Text("Started: \(dateFormatter.string(from: order.createdAt))")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
        Text("Incomplete")
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.orange.opacity(0.2))
          .foregroundColor(.orange)
          .cornerRadius(8)
      }

      // Details
      VStack(alignment: .leading, spacing: 6) {
        if order.phoneNumber != "Unknown" {
          HStack {
            Image(systemName: "phone.fill").foregroundColor(.accentGold)
            Text("Number: \(order.phoneNumber)").font(.subheadline)
          }
        }

        HStack {
          Image(systemName: "sim.fill").foregroundColor(.accentGold)
          Text("SIM Type: \(order.simType)").font(.subheadline)
        }

        if order.deviceBrand != "Unknown" {
          HStack {
            Image(systemName: "iphone").foregroundColor(.accentGold)
            Text("Device: \(order.deviceBrand) \(order.deviceModel)").font(.subheadline)
          }
        }
      }

      // Tasks
      if !order.missingTasks.isEmpty {
        VStack(alignment: .leading, spacing: 4) {
          Text("Tasks to Complete:")
            .font(.subheadline)
            .fontWeight(.medium)
          ForEach(order.missingTasks.prefix(2), id: \.self) { task in
            HStack {
              Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.orange)
              Text(task).font(.caption)
            }
          }

          if order.missingTasks.count > 2 {
            Text("+\(order.missingTasks.count - 2) more tasks")
              .font(.caption2)
              .foregroundColor(.secondary)
              .italic()
          }
        }
      }

      Spacer()

      // Buttons
      VStack(spacing: 8) {
        NavigationLink(destination: OrderDetailView(orderId: order.id)) {
          Label("View Details", systemImage: "info.circle")
            .foregroundColor(.accentGold)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentGold.opacity(0.1))
            .cornerRadius(8)
        }

        Button(action: { onComplete(order.id) }) {
          Label("Complete Setup", systemImage: "checkmark.circle.fill")
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
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
    .frame(maxWidth: .infinity, minHeight: 320, maxHeight: 360)
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
      Circle().fill(statusColor).frame(width: 12, height: 12)
      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text("Order #\(order.id.prefix(8))")
            .font(.body)
            .fontWeight(.medium)
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

struct PlanCarousel: View {
    let plans: [Plan]
    @Binding var selectedPlan: Plan?
    @Binding var planNavIsActive: Bool
    var onStart: ((String) -> Void)?

    var body: some View {
        HStack {
            ForEach(plans) { plan in
                NavigationLink(
                    destination: PlanDetailView(plan: plan),
                    isActive: Binding(
                        get: { self.selectedPlan?.id == plan.id && self.planNavIsActive },
                        set: { val in if !val { self.selectedPlan = nil } }
                    )
                ) {
                    PlanCardView(plan: plan)
                        .frame(width: 300)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    self.selectedPlan = plan
                    self.planNavIsActive = true
                })
            }
        }
        .frame(height: 150)
    }
}

#Preview {
  ExistingUserView(previousOrders: [])
    .environmentObject(UserRegistrationViewModel())
}

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
  @State private var availablePlans: [Plan] = []
  @State private var isLoadingPlans = false
  @State private var showPlanSelection = false
  @State private var selectedPlan: Plan?
  @State private var currentPlanIndex = 0
  @State private var carouselTimer: Timer?
  @State private var showPlanDetailsSheet = false
  @EnvironmentObject private var navigationState: NavigationState

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()

      VStack(spacing: 0) {
        // FIXED HEADER
        AppHeader {
          Image("Trump_Mobile_logo_gold")
            .resizable()
            .aspectRatio(80.0/23.0, contentMode: .fit)
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

        // SCROLLABLE MIDDLE CONTENT
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

            // Incomplete Tasks Section (Priority display)
            if !incompleteOrders.isEmpty {
              incompleteTasksSection
            }
            
            // Plans section
            if isLoadingPlans {
              ProgressView("Loading plans...")
                .padding()
            } else if !availablePlans.isEmpty {
              VStack(alignment: .leading, spacing: 12) {
                Text("Available Plans")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(.primary)
                
                // Carousel View - shows one plan at a time
                TabView(selection: $currentPlanIndex) {
                  ForEach(Array(availablePlans.enumerated()), id: \.element.plan_id) { index, plan in
                    DetailedPlanCarouselCard(
                      plan: plan,
                      isSelected: selectedPlan?.plan_id == plan.plan_id,
                      onSelect: {
                        selectedPlan = plan
                        stopCarouselTimer()  // Stop the timer when user manually selects a plan
                        showPlanDetailsSheet = true
                      }
                    )
                    .tag(index)
                    .padding(.horizontal, 4)
                  }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Page indicators
                HStack {
                  Spacer()
                  HStack(spacing: 8) {
                    ForEach(0..<availablePlans.count, id: \.self) { index in
                      Circle()
                        .fill(currentPlanIndex == index ? Color.accentGold : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut(duration: 0.3), value: currentPlanIndex)
                    }
                  }
                  Spacer()
                }
                .padding(.top, 8)
              }
              .padding()
              .background(Color(.systemGray6))
              .cornerRadius(12)
              .onAppear {
                startCarouselTimer()
              }
              .onDisappear {
                stopCarouselTimer()
              }
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
              .background(Color.adaptiveSecondaryBackground)
              .cornerRadius(12)
            }

            Spacer(minLength: 20)
          }
          .padding(.horizontal)
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
      NavigationView {
        PrivacyPolicyView()
      }
    }
    .sheet(isPresented: $navigationState.showTermsAndConditions) {
      NavigationView {
        TermsAndConditionsView()
      }
    }
    .sheet(isPresented: $showPlanSelection) {
      NavigationView {
        PlanSelectionView(plans: availablePlans) { plan in
          selectedPlan = plan
          showPlanSelection = false
        }
        .navigationTitle("Select Plan")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    .sheet(isPresented: $showPlanDetailsSheet) {
      if let plan = selectedPlan {
        PlanDetailsSheetView(
          plan: plan,
          onStartOrder: { [self] in
            showPlanDetailsSheet = false
            createNewOrderAndStart()
          },
          onClose: { [self] in
            selectedPlan = nil  // Deselect the plan
            showPlanDetailsSheet = false
            // Restart the carousel timer when sheet closes
            startCarouselTimer()
          }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
      }
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
      
      // Load plans
      loadPlans()
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

    // Get plan information from selected plan
    let planId = selectedPlan?.plan_id
    let planName = selectedPlan?.display_name ?? selectedPlan?.plan_name ?? "Telgoo5 Mobile Plan"
    let planPrice = selectedPlan?.total_plan_price

    // Create order first, then start the flow
    FirebaseManager.shared.createNewOrder(
      userId: userId,
      planId: planId,
      planName: planName,
      planPrice: planPrice
    ) { orderId, error in
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
    guard Auth.auth().currentUser?.uid != nil else {
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
  
  private func loadPlans() {
    isLoadingPlans = true
    
    // Get zip code - you may want to get this from user's saved address or location
    // For now, using a default. Replace with actual zip code from user data
    let zipCode = "60644" // TODO: Get from user's shipping address or location
    
    VCareAPIManager.shared.getPlanList(
      zipCode: zipCode,
      enrollmentType: "NON_LIFELINE",
      isFamilyPlan: "N",
      agentId: "Sushil",
      source: "API"
    ) { [self] result in
      DispatchQueue.main.async {
        isLoadingPlans = false
        switch result {
        case .success(let plans):
          availablePlans = plans
          print("✅ Loaded \(plans.count) plans")
          // Reset carousel to first plan
          currentPlanIndex = 0
          // Don't auto-select - let user select manually
          selectedPlan = nil
          // Start timer if plans are available
          if !plans.isEmpty {
            startCarouselTimer()
          }
        case .failure(let error):
          print("❌ Failed to load plans: \(error.localizedDescription)")
          // Don't show error as it's not critical for order creation
        }
      }
    }
  }
  
  private func startCarouselTimer() {
    stopCarouselTimer() // Ensure no duplicate timers
    guard !availablePlans.isEmpty else { return }
    
    carouselTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
      guard !self.availablePlans.isEmpty else { return }
      DispatchQueue.main.async {
        var transaction = Transaction(animation: .easeInOut(duration: 0.6))
        transaction.disablesAnimations = false
        withTransaction(transaction) {
          let nextIndex = (self.currentPlanIndex + 1) % self.availablePlans.count
          self.currentPlanIndex = nextIndex
          // Only rotate visually, don't auto-select plans
        }
      }
    }
  }
  
  private func stopCarouselTimer() {
    carouselTimer?.invalidate()
    carouselTimer = nil
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

// MARK: - Detailed Plan Carousel Card
struct DetailedPlanCarouselCard: View {
  let plan: Plan
  let isSelected: Bool
  let onSelect: () -> Void
  
  var body: some View {
    Button(action: onSelect) {
      VStack(alignment: .leading, spacing: 12) {
        // Header with plan name and price
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(plan.display_name ?? plan.plan_name)
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            
            if let displayDescription = plan.display_description, !displayDescription.isEmpty {
              Text(displayDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
          
          Spacer()
          
          VStack(alignment: .trailing, spacing: 2) {
            Text("$\(plan.total_plan_price)")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundStyle(
                LinearGradient(
                  gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
            Text("/month")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.accentGold)
              .font(.title3)
          }
        }
        
        // Plan details: Calls, Messages, Data
        HStack(spacing: 16) {
          // Calls/Minutes
          VStack(spacing: 4) {
            Image(systemName: "phone.fill")
              .font(.title3)
              .foregroundColor(.accentGold)
            Text(formatTalk(plan))
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
            Text("Calls")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          
          Divider()
            .frame(height: 40)
          
          // Messages/Texts
          VStack(spacing: 4) {
            Image(systemName: "message.fill")
              .font(.title3)
              .foregroundColor(.accentGold)
            Text(formatText(plan))
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
            Text("Messages")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
          
          Divider()
            .frame(height: 40)
          
          // Data
          VStack(spacing: 4) {
            Image(systemName: "antenna.radiowaves.left.and.right")
              .font(.title3)
              .foregroundColor(.accentGold)
            Text(formatData(plan))
              .font(.subheadline)
              .fontWeight(.semibold)
              .foregroundColor(.primary)
            Text("Data")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity)
        }
        
        // Add subtle click indicator
        HStack(spacing: 4) {
          Text(isSelected ? "Selected" : "Tap to select")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(
              LinearGradient(
                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                startPoint: .leading,
                endPoint: .trailing
              )
            )
          Image(systemName: "chevron.right")
            .font(.caption2)
            .foregroundStyle(
              LinearGradient(
                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                startPoint: .leading,
                endPoint: .trailing
              )
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
      }
      .padding()
      .background(isSelected ? Color.accentGold.opacity(0.1) : Color(.systemBackground))
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? Color.accentGold : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
  
  private func formatTalk(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.talk >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value
    if plan.talk >= 1000 {
      return "\(plan.talk / 1000)K"
    }
    return "\(plan.talk)"
  }
  
  private func formatText(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.text >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value
    if plan.text >= 1000 {
      return "\(plan.text / 1000)K"
    }
    return "\(plan.text)"
  }
  
  private func formatData(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.data >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value (using decimal base: 1000 MB = 1 GB)
    if plan.data >= 1000 {
      let gigabytes = Double(plan.data) / 1000.0
      return "\(Int(gigabytes.rounded()))GB"
    }
    return "\(plan.data)MB"
  }
}

// MARK: - Plan Details Sheet View
struct PlanDetailsSheetView: View {
  let plan: Plan
  let onStartOrder: () -> Void
  let onClose: () -> Void
  
  @State private var isCreatingOrder = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          // Plan Header
          VStack(alignment: .leading, spacing: 12) {
            Text(plan.display_name ?? plan.plan_name)
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            
            // Only show description if it's different from the plan name
            if let displayDescription = plan.display_description, 
               !displayDescription.isEmpty, 
               displayDescription != (plan.display_name ?? plan.plan_name) {
              Text(displayDescription)
                .font(.headline)
                .foregroundColor(.secondary)
            } else if plan.plan_description != (plan.display_name ?? plan.plan_name) {
              Text(plan.plan_description)
                .font(.headline)
                .foregroundColor(.secondary)
            }
            
            HStack {
              Text("$\(plan.total_plan_price)")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
              
              Text("/month")
                .font(.title3)
                .foregroundColor(.secondary)
            }
          }
          .padding(.horizontal)
          .padding(.top)
          
          Divider()
            .padding(.horizontal)
          
          // Plan Features
          VStack(alignment: .leading, spacing: 16) {
            // Data, Talk, Text
            VStack(spacing: 16) {
              PlanDetailRow(
                icon: "antenna.radiowaves.left.and.right",
                title: "Data",
                value: formatData(plan)
              )
              
              PlanDetailRow(
                icon: "phone.fill",
                title: "Talk/Minutes",
                value: formatTalk(plan)
              )
              
              PlanDetailRow(
                icon: "message.fill",
                title: "Text/Messages",
                value: formatText(plan)
              )
            }
            .padding(.horizontal)
            
            Divider()
              .padding(.horizontal)
            
            // Additional Details
            VStack(alignment: .leading, spacing: 12) {
              PlanInfoRow(
                label: "Plan Type",
                value: plan.is_prepaid_postpaid.capitalized
              )
              
              PlanInfoRow(
                label: "Plan Expiry",
                value: "\(plan.plan_expiry_days) days (\(plan.plan_expiry_type))"
              )
              
              PlanInfoRow(
                label: "Carrier",
                value: plan.carrier.joined(separator: ", ")
              )
              
              if plan.is_familyplan == "Y" {
                PlanInfoRow(
                  label: "Family Plan",
                  value: "Available"
                )
              }
              
              if plan.autopay_discount == "Y" {
                PlanInfoRow(
                  label: "Autopay Discount",
                  value: "Available"
                )
              }
              
              if !plan.plan_discount_details.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                  Text("Discount Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                  
                  ForEach(plan.plan_discount_details, id: \.self) { discount in
                    HStack {
                      Image(systemName: "tag.fill")
                        .foregroundColor(.accentGold)
                      Text(discount)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                  }
                }
                .padding(.top, 8)
              }
              
              if !plan.display_features_description.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                  Text("Features")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.top, 8)
                  
                  ForEach(plan.display_features_description, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 8) {
                      Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentGold)
                      Text(feature)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                  }
                }
              }
            }
            .padding(.horizontal)
          }

          // Spacer to push button to bottom
          Spacer(minLength: 100)
          
          // Start Order Button
          PrimaryGradientButton(
            title: isCreatingOrder ? "Creating order…" : "Start Order",
            isDisabled: isCreatingOrder,
            action: {
              isCreatingOrder = true
              onStartOrder()
            }
          )
          .padding(.horizontal)
          .padding(.top, 20)
          .padding(.bottom, 20)
        }
        .frame(minHeight: UIScreen.main.bounds.height * 0.85)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Close") {
            onClose()
          }
          .foregroundColor(.accentGold)
        }
      }
    }
  }
  
  private func formatData(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.data >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value (using decimal base: 1000 MB = 1 GB)
    if plan.data >= 1000 {
      let gigabytes = Double(plan.data) / 1000.0
      return "\(Int(gigabytes.rounded())) GB"
    }
    return "\(plan.data) MB"
  }
  
  private func formatTalk(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.talk >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value
    if plan.talk >= 1000 {
      return "\(plan.talk / 1000)K minutes"
    }
    return "\(plan.talk) minutes"
  }
  
  private func formatText(_ plan: Plan) -> String {
    // Check if value is extremely large (truly unlimited)
    if plan.text >= 999999999 {
      return "Unlimited"
    }
    // Show actual formatted value
    if plan.text >= 1000 {
      return "\(plan.text / 1000)K messages"
    }
    return "\(plan.text) messages"
  }
}

// MARK: - Supporting Views for Plan Details Sheet
struct PlanDetailRow: View {
  let icon: String
  let title: String
  let value: String
  
  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .font(.title2)
        .foregroundStyle(
          LinearGradient(
            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .frame(width: 40)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .foregroundColor(.secondary)
        Text(value)
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
      }
      
      Spacer()
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }
}

struct PlanInfoRow: View {
  let label: String
  let value: String
  
  var body: some View {
    HStack {
      Text(label)
        .font(.subheadline)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.primary)
    }
  }
}

#Preview {
  ExistingUserStartOrderView(previousOrders: [])
    .environmentObject(UserRegistrationViewModel())
}

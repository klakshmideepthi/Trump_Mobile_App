import FirebaseAuth
import SwiftUI

struct PreviousOrdersView: View {
  let orders: [TrumpOrder]?
  @State private var loadedOrders: [TrumpOrder] = []
  @State private var isLoading = false
  @Environment(\.dismiss) private var dismiss
  @State private var scrollOffset: CGFloat = 0

  // Helper method to get current user identifier for logging
  private var currentUserIdentifier: String {
    if let user = FirebaseAuth.Auth.auth().currentUser {
      return user.email ?? "User ID: \(user.uid)"
    }
    return "Unknown User"
  }

  // Initializers for backward compatibility
  init(orders: [TrumpOrder]) {
    self.orders = orders
  }

  init() {
    self.orders = nil
  }

  // Use provided orders or loaded orders
  private var displayOrders: [TrumpOrder] {
    if let orders = orders {
      return orders
    } else {
      return loadedOrders
    }
  }

  // Computed property to get only completed orders
  private var completedOrders: [TrumpOrder] {
    displayOrders.filter { $0.status == .completed }
  }

  // Computed property to get recent orders (pending, processing, or recent orders within last 30 days)
  private var recentOrders: [TrumpOrder] {
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    return displayOrders.filter { order in
      order.status != .completed && order.status != .cancelled || order.orderDate >= thirtyDaysAgo
    }.filter { $0.status != .completed }
  }

  var body: some View {
    ZStack(alignment: .top) {
      // Background gradient
      LinearGradient(
        colors: [Color.trumpBackground, Color.trumpBackground.opacity(0.95)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()

      Group {
        if orders == nil && isLoading {
          VStack(spacing: 20) {
            ProgressView()
              .scaleEffect(1.5)
              .progressViewStyle(CircularProgressViewStyle(tint: .accentGold))

            Text("Loading your orders...")
              .font(.headline)
              .foregroundColor(.primary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding(.top, 60)
        } else if displayOrders.isEmpty {
          // Enhanced empty state
          VStack(spacing: 24) {
            HStack {
              Spacer()
              Button("Close") { dismiss() }
                .foregroundColor(.accentColor)
                .font(.body)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)

            Text("Previous Orders")
              .font(.largeTitle)
              .fontWeight(.bold)
              .foregroundColor(.primary)
              .padding(.horizontal, 16)

            ZStack {
              Circle()
                .fill(Color.accentGold.opacity(0.1))
                .frame(width: 120, height: 120)

              Image(systemName: "bag")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.accentGold)
            }

            VStack(spacing: 12) {
              Text("No Previous Orders")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

              Text(
                "Your order history will appear here once you make your first purchase with Telgoo5 Mobile."
              )
              .font(.body)
              .multilineTextAlignment(.center)
              .foregroundColor(.secondary)
              .lineLimit(3)
              .padding(.horizontal, 32)
            }

            Button(action: {
              // Add action to start new order
            }) {
              HStack {
                Image(systemName: "plus.circle.fill")
                Text("Start Your First Order")
              }
              .font(.headline)
              .foregroundColor(.white)
              .padding(.horizontal, 24)
              .padding(.vertical, 12)
              .background(Color.accentGold)
              .cornerRadius(25)
              .shadow(color: .accentGold.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .padding(.top, 8)

            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .padding()
        } else {
          ScrollView {
            VStack(spacing: 16) {
              // Top spacing + close
              HStack {
                Spacer()
                Button("Close") { dismiss() }
                  .foregroundColor(.accentColor)
                  .font(.body)
              }
              .padding(.horizontal, 16)
              .padding(.top, 20)

              // Header with scroll tracking
              Text("Previous Orders")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .background(
                  GeometryReader { geo in
                    Color.clear
                      .onAppear { scrollOffset = geo.frame(in: .global).minY }
                      .onChange(of: geo.frame(in: .global).minY) { _, v in scrollOffset = v }
                  }
                )

              LazyVStack(spacing: 12) {
                // Recent Orders Section
                if !recentOrders.isEmpty {
                  VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                      title: "Recent Orders",
                      subtitle: "Orders in progress or recently started",
                      icon: "clock.fill"
                    )

                    ForEach(recentOrders) { order in
                      NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                        OrderCardView(order: order)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }
                  .padding(.horizontal, 16)
                }

                // Completed Orders Section
                if !completedOrders.isEmpty {
                  VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(
                      title: "Completed Orders",
                      subtitle: "Successfully completed purchases",
                      icon: "checkmark.circle.fill"
                    )

                    ForEach(completedOrders) { order in
                      NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                        OrderCardView(order: order)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }
                  .padding(.horizontal, 16)
                }
              }
              .padding(.vertical, 20)

              Spacer(minLength: 80)
            }
          }
        }
      }

      // Sticky Header
      if scrollOffset < -80 && !displayOrders.isEmpty {
        VStack(spacing: 0) {
          HStack {
            Text("Previous Orders")
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(.primary)
            Spacer()
            Button("Close") { dismiss() }
              .foregroundColor(.accentColor)
              .font(.body)
          }
          .padding()
          .background(Color(.systemBackground).opacity(0.95))
          .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.3), value: scrollOffset)
      }
    }
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      // Log which user's orders are being displayed
      DebugLogger.shared.logUserInfoRetrieval(
        for: currentUserIdentifier, context: "Viewing Previous Orders")

      // Only load orders if they weren't provided
      if orders == nil {
        print("DEBUG: PreviousOrdersView - No orders provided, loading from Firebase")
        DebugLogger.shared.log(
          "No orders provided for \(currentUserIdentifier), loading from Firebase",
          category: "PreviousOrders")
        loadOrders()
      } else {
        print("DEBUG: PreviousOrdersView - Using provided orders: \(orders?.count ?? 0)")
        DebugLogger.shared.log(
          "Displaying \(orders?.count ?? 0) provided orders for \(currentUserIdentifier)",
          category: "PreviousOrders")
      }
    }
  }

  private func loadOrders() {
    print("DEBUG: PreviousOrdersView - Starting to load orders")
    DebugLogger.shared.log(
      "Starting to load orders for \(currentUserIdentifier)", category: "PreviousOrders")

    isLoading = true
    FirebaseOrderManager.shared.fetchUserOrders { fetchedOrders in
      DispatchQueue.main.async {
        print("DEBUG: PreviousOrdersView - Loaded \(fetchedOrders.count) orders")
        DebugLogger.shared.log(
          "Successfully loaded \(fetchedOrders.count) orders for \(self.currentUserIdentifier)",
          category: "PreviousOrders")

        // Log order details for debugging
        for (index, order) in fetchedOrders.enumerated() {
          DebugLogger.shared.log(
            "Order \(index + 1): \(order.planName), Status: \(order.status), Amount: $\(order.amount)",
            category: "PreviousOrders")
        }

        self.loadedOrders = fetchedOrders
        self.isLoading = false
      }
    }
  }
}

// MARK: - Section Header Component
struct SectionHeader: View {
  let title: String
  let subtitle: String
  let icon: String

  var body: some View {
    HStack(spacing: 12) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color.accentGold.opacity(0.15))
          .frame(width: 32, height: 32)

        Image(systemName: icon)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.accentGold)
      }

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.primary)

        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Spacer()
    }
  }
}

struct CompletedOrdersView: View {
  @State private var completedOrders: [TrumpOrder] = []
  @State private var isLoading = true

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()

      VStack {
        if isLoading {
          VStack(spacing: 20) {
            ProgressView()
              .scaleEffect(1.5)
              .progressViewStyle(CircularProgressViewStyle(tint: .accentGold))

            Text("Loading completed orders...")
              .font(.headline)
              .foregroundColor(.primary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if completedOrders.isEmpty {
          VStack(spacing: 24) {
            ZStack {
              Circle()
                .fill(Color.green.opacity(0.1))
                .frame(width: 120, height: 120)

              Image(systemName: "checkmark.circle")
                .font(.system(size: 50, weight: .light))
                .foregroundColor(.green)
            }

            VStack(spacing: 12) {
              Text("No Completed Orders")
                .font(.title2)
                .fontWeight(.bold)

              Text(
                "Your completed order history will appear here once you complete your first purchase."
              )
              .font(.body)
              .multilineTextAlignment(.center)
              .foregroundColor(.secondary)
              .padding(.horizontal, 40)
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
          ScrollView {
            LazyVStack(spacing: 16) {
              ForEach(completedOrders) { order in
                NavigationLink(destination: OrderDetailView(orderId: order.id)) {
                  OrderRowView(order: order)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding()
          }
        }
      }
    }
    .navigationTitle("Completed Orders")
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      loadCompletedOrders()
    }
  }

  private func loadCompletedOrders() {
    isLoading = true
    FirebaseOrderManager.shared.fetchCompletedOrders { orders in
      DispatchQueue.main.async {
        self.completedOrders = orders
        self.isLoading = false
      }
    }
  }
}

struct OrderRowView: View {
  let order: TrumpOrder

  var body: some View {
    HStack(spacing: 16) {
      // Status indicator with improved design
      VStack {
        ZStack {
          Circle()
            .fill(statusColor.opacity(0.2))
            .frame(width: 40, height: 40)

          Circle()
            .fill(statusColor)
            .frame(width: 12, height: 12)
        }
        Spacer()
      }

      // Order content
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(order.planName)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)

          Spacer()

          Text("$\(order.amount, specifier: "%.2f")")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.accentGold)
        }

        HStack {
          Text(order.orderDate, style: .date)
            .font(.subheadline)
            .foregroundColor(.secondary)

          Spacer()

          StatusBadge(status: order.status)
        }

        // Order details
        VStack(alignment: .leading, spacing: 4) {
          if let phoneNumber = order.phoneNumber, !phoneNumber.isEmpty {
            HStack(spacing: 8) {
              Image(systemName: "phone.fill")
                .foregroundColor(.accentGold)
                .frame(width: 16)
              Text("Phone: \(phoneNumber)")
                .font(.subheadline)
                .foregroundColor(.primary)
            }
          }

          HStack(spacing: 8) {
            Image(systemName: "sim.fill")
              .foregroundColor(.accentGold)
              .frame(width: 16)
            Text("SIM: \(order.simType)")
              .font(.subheadline)
              .foregroundColor(.primary)
          }
        }
      }

      // Enhanced chevron
      VStack {
        Spacer()
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.accentGold)
          .opacity(0.8)
        Spacer()
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
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

struct RecentOrderRowView: View {
  let order: TrumpOrder

  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }()

  var body: some View {
    HStack(spacing: 16) {
      // Progress indicator for recent orders
      VStack {
        ZStack {
          Circle()
            .stroke(Color.accentGold.opacity(0.3), lineWidth: 3)
            .frame(width: 40, height: 40)

          Circle()
            .fill(Color.accentGold)
            .frame(width: 16, height: 16)

          // Animated pulse effect
          Circle()
            .stroke(Color.accentGold.opacity(0.6), lineWidth: 2)
            .frame(width: 50, height: 50)
            .scaleEffect(1.2)
            .opacity(0.7)
        }
        Spacer()
      }

      VStack(alignment: .leading, spacing: 12) {
        // Header section
        HStack {
          VStack(alignment: .leading, spacing: 6) {
            Text(order.planName)
              .font(.headline)
              .fontWeight(.bold)
              .foregroundColor(.primary)

            Text("Started: \(dateFormatter.string(from: order.orderDate))")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }

          Spacer()

          VStack(alignment: .trailing, spacing: 6) {
            Text("$\(order.amount, specifier: "%.2f")")
              .font(.title3)
              .fontWeight(.bold)
              .foregroundColor(.accentGold)

            StatusBadge(status: order.status)
          }
        }

        // Order details with improved spacing
        VStack(alignment: .leading, spacing: 8) {
          if let phoneNumber = order.phoneNumber, !phoneNumber.isEmpty {
            HStack(spacing: 12) {
              Image(systemName: "phone.fill")
                .foregroundColor(.accentGold)
                .frame(width: 18)
              Text("Phone: \(phoneNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }
          }

          HStack(spacing: 12) {
            Image(systemName: "sim.fill")
              .foregroundColor(.accentGold)
              .frame(width: 18)
            Text("SIM: \(order.simType)")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.primary)
          }
        }

        // Call to action
        HStack(spacing: 8) {
          Image(systemName: "exclamationmark.circle.fill")
            .foregroundColor(.accentGold)
          Text("Tap to continue setup")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.accentGold)
          Spacer()
        }
        .padding(.top, 4)
      }

      // Enhanced chevron for recent orders
      VStack {
        Spacer()
        ZStack {
          Circle()
            .fill(Color.accentGold.opacity(0.1))
            .frame(width: 32, height: 32)

          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.accentGold)
        }
        Spacer()
      }
    }
    .padding(20)
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 16)
            .stroke(
              LinearGradient(
                colors: [Color.accentGold.opacity(0.4), Color.accentGold.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 2
            )
        )
        .shadow(color: .accentGold.opacity(0.15), radius: 12, x: 0, y: 6)
    )
  }
}

struct StatusBadge: View {
  let status: TrumpOrder.OrderStatus

  var body: some View {
    HStack(spacing: 4) {
      Image(systemName: statusIcon)
        .font(.system(size: 10, weight: .bold))

      Text(status.displayName)
        .font(.caption)
        .fontWeight(.semibold)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 6)
    .background(backgroundColor)
    .foregroundColor(.white)
    .cornerRadius(12)
    .shadow(color: backgroundColor.opacity(0.3), radius: 4, x: 0, y: 2)
  }

  private var backgroundColor: Color {
    switch status {
    case .pending:
      return .orange
    case .completed:
      return .green
    case .cancelled:
      return .red
    }
  }

  private var statusIcon: String {
    switch status {
    case .pending:
      return "clock.fill"
    case .completed:
      return "checkmark.circle.fill"
    case .cancelled:
      return "xmark.circle.fill"
    }
  }
}

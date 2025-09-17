import SwiftUI

struct PreviousOrdersView: View {
  let orders: [TrumpOrder]?
  @State private var loadedOrders: [TrumpOrder] = []
  @State private var isLoading = false

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

  var body: some View {
    VStack {
      if orders == nil && isLoading {
        ProgressView("Loading orders...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if displayOrders.isEmpty {
        VStack(spacing: 20) {
          Image(systemName: "bag")
            .font(.system(size: 60))
            .foregroundColor(.secondary)

          Text("No Previous Orders")
            .font(.title2)
            .fontWeight(.semibold)

          Text("Your order history will appear here once you make your first purchase.")
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(displayOrders) { order in
          OrderRowView(order: order)
        }
      }
    }
    .navigationTitle("Previous Orders")
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      // Only load orders if they weren't provided
      if orders == nil {
        print("DEBUG: PreviousOrdersView - No orders provided, loading from Firebase")
        loadOrders()
      } else {
        print("DEBUG: PreviousOrdersView - Using provided orders: \(orders?.count ?? 0)")
      }
    }
  }

  private func loadOrders() {
    print("DEBUG: PreviousOrdersView - Starting to load orders")
    isLoading = true
    FirebaseOrderManager.shared.fetchUserOrders { fetchedOrders in
      DispatchQueue.main.async {
        print("DEBUG: PreviousOrdersView - Loaded \(fetchedOrders.count) orders")
        self.loadedOrders = fetchedOrders
        self.isLoading = false
      }
    }
  }
}

struct CompletedOrdersView: View {
  @State private var completedOrders: [TrumpOrder] = []
  @State private var isLoading = true

  var body: some View {
    VStack {
      if isLoading {
        ProgressView("Loading completed orders...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if completedOrders.isEmpty {
        VStack(spacing: 20) {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 60))
            .foregroundColor(.secondary)

          Text("No Completed Orders")
            .font(.title2)
            .fontWeight(.semibold)

          Text(
            "Your completed order history will appear here once you complete your first purchase."
          )
          .font(.body)
          .multilineTextAlignment(.center)
          .foregroundColor(.secondary)
          .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(completedOrders) { order in
          OrderRowView(order: order)
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
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(order.planName)
          .font(.headline)

        Spacer()

        Text("$\(order.amount, specifier: "%.2f")")
          .font(.headline)
          .foregroundColor(.accentColor)
      }

      HStack {
        Text(order.orderDate, style: .date)
          .font(.caption)
          .foregroundColor(.secondary)

        Spacer()

        StatusBadge(status: order.status)
      }

      if let phoneNumber = order.phoneNumber {
        Text("Phone: \(phoneNumber)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      Text("SIM: \(order.simType)")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.vertical, 4)
  }
}

struct StatusBadge: View {
  let status: TrumpOrder.OrderStatus

  var body: some View {
    Text(status.displayName)
      .font(.caption)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(backgroundColor)
      .foregroundColor(.white)
      .cornerRadius(8)
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
}

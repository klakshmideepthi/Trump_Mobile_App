import SwiftUI
import FirebaseAuth

struct ExistingUserStartOrderView: View {
    var previousOrders: [TrumpOrder] = []
    var onStart: ((String?) -> Void)?
    var onLogout: (() -> Void)?
    
    @State private var isMenuOpen = false
    @State private var loadedOrders: [TrumpOrder] = []
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
                        .frame(height: 40)
                    
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
                                        OrderCardView(order: order)
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
                                
                                Text("Start your first Trump Mobile order below!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(30)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 100) // Space for bottom button
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
        }
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
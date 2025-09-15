import SwiftUI
import FirebaseAuth

struct ExistingUserStartOrderView: View {
    var previousOrders: [TrumpOrder] = []
    var onStart: ((String?) -> Void)?
    var onLogout: (() -> Void)?
    
    @State private var isMenuOpen = false
    @State private var loadedOrders: [TrumpOrder] = []
    @State private var isLoading = true
    @EnvironmentObject private var navigationState: NavigationState
    
    var body: some View {
        ZStack {
            Color.trumpBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header with logo and hamburger menu
                HStack {
                    // Trump Mobile Logo
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
                    Button(action: {
                        onStart?(nil)
                    }) {
                        Text("Start a New Order")
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
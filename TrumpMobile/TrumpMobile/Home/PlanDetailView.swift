import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct PlanDetailView: View {
    let plan: Plan
    
    @State private var showInternationalDetails = false
    @State private var errorMessage: String? = nil
    @State private var isCreatingOrder = false
    
    // Programmatic navigation to order flow (no EnvironmentObject needed)
    @State private var pushOrderFlow = false
    @State private var createdOrderId: String? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Order flow is presented via fullScreenCover below
            
            // Header
            AppHeader {
                Image("Trump_Mobile_logo_gold")
                    .resizable()
                    .aspectRatio(80.0/23.0, contentMode: .fit)
                    .frame(height: 25)
                    .clipped()
                Spacer()
            }
            .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Plan Title Section
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(plan.name.uppercased())
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
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
                                            endPoint: .trailing))
                                Text("plan")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color(.systemBackground))
                            }
                        }
                        .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.top, 20)
                    
                    // Price
                    Text(String(format: "$%.2f/month", plan.price))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                startPoint: .leading,
                                endPoint: .trailing))
                        .padding(.bottom, 10)
                    
                    // Features
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
                                        endPoint: .trailing))
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
                                                endPoint: .trailing))
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
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
            }
            
            // Start Order Button
            Button(action: startOrderFlow) {
                if isCreatingOrder {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                        .padding()
                } else {
                    Text("Start Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient(
                            gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                            startPoint: .leading, endPoint: .trailing))
                        .cornerRadius(12)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showInternationalDetails) {
            NavigationView {
                InternationalLongDistanceView()
            }
        }
        .fullScreenCover(isPresented: $pushOrderFlow) {
            OrderFlowView(orderId: createdOrderId ?? "")
        }
    }
    
    // MARK: - Start Order Flow
    private func startOrderFlow() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in."
            return
        }

        isCreatingOrder = true
        FirebaseManager.shared.createNewOrder(userId: userId, planId: plan.id) { orderId, error in
            isCreatingOrder = false
            
            if let error = error {
                errorMessage = "Failed to create order: \(error.localizedDescription)"
                return
            }

            guard let orderId = orderId else {
                errorMessage = "Order ID could not be generated."
                return
            }

            print("✅ Created order \(orderId) for plan \(plan.id)")
            UserDefaults.standard.set(orderId, forKey: "currentOrderId")
            
            // Push into the order flow
            createdOrderId = orderId
            pushOrderFlow = true
        }
    }
}

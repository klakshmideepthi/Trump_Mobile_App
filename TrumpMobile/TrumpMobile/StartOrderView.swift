import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24, height: 24)
                .foregroundColor(Color.accentGold)
            
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
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header section
                Text("ALL-AMERICAN PERFORMANCE.\nEVERYDAY PRICE.")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.trumpText)
                    .padding(.top, 20)
                
                // Price section
                Text("$47.45/MONTH.")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color.accentGold)
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
                            .foregroundColor(Color.accentGold)
                        
                        VStack(alignment: .leading) {
                            Text("International Calling to 100 destinations")
                                .foregroundColor(.trumpText)
                            Button(action: {
                                showInternationalDetails.toggle()
                            }) {
                                Text("see details here")
                                    .foregroundColor(Color.accentGold)
                                    .underline()
                            }
                        }
                    }
                    
                    FeatureRow(icon: "creditcard.fill", text: "No Credit Check")
                }
                .padding(.bottom, 20)
                
                // Plan badge
                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 120, height: 120)
                        
                        VStack(spacing: 0) {
                            Text("THE")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("47")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(Color.accentGold)
                            Text("PLAN")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
                
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Spacer()
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Enroll button
                Button(action: createNewOrder) {
                    Text("Enroll in Trump™ Mobile Now")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentGold)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                }
                .padding(.vertical)
                .disabled(isLoading)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showInternationalDetails) {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("International Calling Destinations")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("Includes calls to landlines and mobile numbers in 100 international destinations, including:")
                            .padding(.bottom, 5)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                            Text("• Canada")
                            Text("• Mexico")
                            Text("• United Kingdom")
                            Text("• Italy")
                            Text("• France")
                            Text("• Germany")
                            Text("• China")
                            Text("• Japan")
                            Text("• Australia")
                            Text("• Brazil")
                            // Add more countries as needed
                        }
                        
                        Text("Fair usage policy applies. Visit website for complete list of destinations and terms.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top)
                    }
                    .padding()
                }
                .navigationTitle("International Calling")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            showInternationalDetails = false
                        }
                    }
                }
            }
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
            
            // Step 2: Copy contact info to the order
            dispatchGroup.enter()
            FirebaseManager.shared.copyContactInfoToOrder(userId: userId, orderId: orderId) { success, error in
                if let error = error {
                    print("Warning: Failed to copy contact info: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
            
            // Step 3: Copy shipping address to the order
            dispatchGroup.enter()
            FirebaseManager.shared.copyShippingAddressToOrder(userId: userId, orderId: orderId) { success, error in
                if let error = error {
                    print("Warning: Failed to copy shipping address: \(error.localizedDescription)")
                }
                dispatchGroup.leave()
            }
            
            // When all copy operations complete
            dispatchGroup.notify(queue: .main) {
                isLoading = false
                // Navigate to next screen with the order ID
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

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

struct CompactPlanCard: View {
  let plan: Plan
  let isSelected: Bool
  let onSelect: () -> Void
  
  var body: some View {
    Button(action: onSelect) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(plan.display_name ?? plan.plan_name)
            .font(.headline)
            .foregroundColor(.trumpText)
          
          if let displayDescription = plan.display_description, !displayDescription.isEmpty {
            Text(displayDescription)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(2)
          }
        }
        
        Spacer()
        
        VStack(alignment: .trailing, spacing: 2) {
          Text("$\(plan.total_plan_price)")
            .font(.title3)
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
        }
      }
      .padding()
      .background(isSelected ? Color.accentGold.opacity(0.1) : Color(.systemGray6))
      .cornerRadius(10)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(isSelected ? Color.accentGold : Color.clear, lineWidth: 2)
      )
      .overlay(
        // Add subtle click indicator
        VStack {
          Spacer()
          HStack(spacing: 4) {
            Text(isSelected ? "Selected" : "Tap to select")
              .font(.caption2)
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
          .padding(.horizontal)
          .padding(.bottom, 8)
        }
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct StartOrderView: View {
  var onStart: (String?) -> Void
  var onLogout: (() -> Void)? = nil
  var onChangeAddress: (() -> Void)? = nil

  @State private var isLoading = false
  @State private var errorMessage: String? = nil
  @State private var showInternationalDetails = false
  @State private var isMenuOpen = false
  @State private var availablePlans: [Plan] = []
  @State private var isLoadingPlans = false
  @State private var showPlanSelection = false
  @State private var selectedPlan: Plan?
  @EnvironmentObject private var navigationState: NavigationState
  
  // Address state variables
  @State private var currentZipCode: String = ""
  @State private var currentAddress: String = ""
  @State private var showAddressSheet = false

  var body: some View {
    return ZStack {
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
          
          // Zip code display with dropdown
          if !currentZipCode.isEmpty {
            Button(action: {
              showAddressSheet = true
            }) {
              HStack(spacing: 4) {
                Text(currentZipCode)
                  .font(.body)
                  .fontWeight(.medium)
                  .foregroundColor(.primary)
                Image(systemName: "chevron.down")
                  .font(.body)
                  .foregroundColor(.secondary)
              }
            }
          }
          
          Spacer()
          
          Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
              isMenuOpen = true
            }
          }) {
            Image(systemName: "line.3.horizontal")
              .font(.title2)
              .foregroundStyle(
                LinearGradient(
                  gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
          }
        }

        // SCROLLABLE MIDDLE CONTENT
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
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
            // Plans section
            if isLoadingPlans {
              ProgressView("Loading plans...")
                .padding()
            } else if !availablePlans.isEmpty {
              VStack(alignment: .leading, spacing: 12) {
                Text("Available Plans")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(.trumpText)
                
                ForEach(availablePlans.prefix(3)) { plan in
                  CompactPlanCard(
                    plan: plan,
                    isSelected: selectedPlan?.plan_id == plan.plan_id,
                    onSelect: {
                      selectedPlan = plan
                    }
                  )
                }
                
                if availablePlans.count > 3 {
                  Button(action: {
                    showPlanSelection = true
                  }) {
                    Text("View All Plans (\(availablePlans.count))")
                      .font(.subheadline)
                      .foregroundStyle(
                        LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                      )
                  }
                }
              }
              .padding(.bottom, 20)
            }
            
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
            Spacer(minLength: 20)  // Reduced space since button is fixed
          }
          .padding(.horizontal, 30)
        }
        // FIXED BOTTOM BUTTON (standardized)
        BottomActionBar {
          PrimaryGradientButton(
            title: "Join Telgoo5 Mobile Now",
            isDisabled: isLoading,
            action: createNewOrder
          )
        }
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
      .sheet(isPresented: $showAddressSheet) {
        AddressInfoSheet(
          currentAddress: currentAddress,
          zipCode: currentZipCode,
          onChangeAddress: {
            // Empty callback - sheet will handle reloading
          }
        )
        .onDisappear {
          // Reload address info when sheet is dismissed
          loadAddressInfo()
        }
      }
      .onAppear {
        loadPlans()
        loadAddressInfo()
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
  }
  
  func createNewOrder() {
    guard let userId = Auth.auth().currentUser?.uid else {
      errorMessage = "Please sign in to create an order"
      return
    }

    isLoading = true
    errorMessage = nil

    // Get plan information from selected plan
    let planId = selectedPlan?.plan_id
    let planName = selectedPlan?.display_name ?? selectedPlan?.plan_name ?? "Telgoo5 Mobile Plan"
    let planPrice = selectedPlan?.total_plan_price

    // Step 1: Create a new order document with plan information
    FirebaseManager.shared.createNewOrder(
      userId: userId,
      planId: planId,
      planName: planName,
      planPrice: planPrice
    ) { orderId, error in
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
  
  func loadPlans() {
    isLoadingPlans = true
    
    // Get zip code from Firebase contact info
    guard let userId = Auth.auth().currentUser?.uid else {
      isLoadingPlans = false
      return
    }
    
    // Helper function to load plans with zip code
    let loadPlansWithZipCode = { [self] (zipCode: String) in
      let enrollmentType = "NON_LIFELINE"
      let isFamilyPlan = "N"
      
      // First, try to get plans from Firestore
      FirebaseManager.shared.getPlans(
        zipCode: zipCode,
        enrollmentType: enrollmentType,
        isFamilyPlan: isFamilyPlan
      ) { [self] cachedPlans, error in
        if let cachedPlans = cachedPlans, !cachedPlans.isEmpty {
          // Plans found in Firestore, use them
          DispatchQueue.main.async {
            isLoadingPlans = false
            availablePlans = cachedPlans
            print("✅ Loaded \(cachedPlans.count) plans from Firestore for zip code: \(zipCode)")
            // Select first plan by default if none selected
            if selectedPlan == nil && !cachedPlans.isEmpty {
              selectedPlan = cachedPlans.first
            }
          }
        } else {
          // Plans not in Firestore, fetch from API
          print("📡 Plans not found in Firestore, fetching from API for zip code: \(zipCode)")
          VCareAPIManager.shared.getPlanList(
            zipCode: zipCode,
            enrollmentType: enrollmentType,
            isFamilyPlan: isFamilyPlan,
            agentId: "Sushil",
            source: "API"
          ) { [self] result in
            DispatchQueue.main.async {
              isLoadingPlans = false
              switch result {
              case .success(let plans):
                availablePlans = plans
                print("✅ Loaded \(plans.count) plans from API for zip code: \(zipCode)")
                
                // Save plans to Firestore for future use
                FirebaseManager.shared.savePlans(
                  zipCode: zipCode,
                  enrollmentType: enrollmentType,
                  isFamilyPlan: isFamilyPlan,
                  plans: plans
                ) { success, error in
                  if success {
                    print("✅ Plans saved to Firestore for zip code: \(zipCode)")
                  } else if let error = error {
                    print("⚠️ Failed to save plans to Firestore: \(error.localizedDescription)")
                  }
                }
                
                // Select first plan by default if none selected
                if selectedPlan == nil && !plans.isEmpty {
                  selectedPlan = plans.first
                }
              case .failure(let error):
                print("❌ Failed to load plans: \(error.localizedDescription)")
                // Don't show error as it's not critical for order creation
              }
            }
          }
        }
      }
    }
    
    // First try to get zip from shipping address
    FirebaseManager.shared.getShippingAddress(userId: userId) { addressData, _ in
      // Check shipping address for zip
      if let zip = addressData?["zip"] as? String, !zip.isEmpty {
        loadPlansWithZipCode(zip)
      } else {
        // Fall back to contact info (if zip is stored there)
        FirebaseManager.shared.getContactInfo(userId: userId) { contactData, _ in
          let zipCode = contactData?["zip"] as? String ?? "60644" // Default fallback
          loadPlansWithZipCode(zipCode)
        }
      }
    }
  }

  // Load address info from Firebase
  private func loadAddressInfo() {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    let previousZipCode = currentZipCode
    
    // Load shipping address
    FirebaseManager.shared.getShippingAddress(userId: userId) { addressData, _ in
      DispatchQueue.main.async {
        if let data = addressData {
          let street = data["street"] as? String ?? ""
          let aptNumber = data["aptNumber"] as? String ?? ""
          let city = data["city"] as? String ?? ""
          let state = data["state"] as? String ?? ""
          let zip = data["zip"] as? String ?? ""
          
          self.currentZipCode = zip
          
          // Build full address string
          var addressParts: [String] = []
          if !street.isEmpty {
            addressParts.append(street)
          }
          if !aptNumber.isEmpty {
            addressParts.append("Apt \(aptNumber)")
          }
          if !city.isEmpty {
            addressParts.append(city)
          }
          if !state.isEmpty {
            addressParts.append(state)
          }
          if !zip.isEmpty {
            addressParts.append(zip)
          }
          
          self.currentAddress = addressParts.joined(separator: ", ")
          
          // Reload plans if ZIP code changed
          // This will check Firestore first, and if plans don't exist for the new zip code,
          // it will fetch from API and save to Firestore
          if previousZipCode != zip && !zip.isEmpty {
            print("📍 ZIP code changed from \(previousZipCode) to \(zip) - reloading plans")
            self.loadPlans()
          }
        }
      }
    }
  }
}

struct StartOrderView_Previews: PreviewProvider {
    static var previews: some View {
      StartOrderView(onStart: { _ in })
    }
  }


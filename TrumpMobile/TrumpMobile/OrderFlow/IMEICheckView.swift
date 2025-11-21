import AVKit
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct IMEICheckView: View {
  @Binding var isPresented: Bool
  var viewModel: UserRegistrationViewModel?  // Optional viewModel to store eSIM availability
  @State private var imeiNumber: String = ""
  @State private var selectedTab = 0
  @State private var showVideoSheet = false
  @State private var isCheckingCompatibility = false
  @State private var compatibilityResult: DeviceCompatibilityData?
  @State private var compatibilityError: String?
  @State private var showCompatibilityResult = false
  @State private var showErrorAlert = false
  var onSubmitIMEI: ((String, Bool?) -> Void)? = nil  // Closure to pass IMEI and compatibility result (nil if not checked)
  
  // Computed property to get digits only from IMEI
  private var imeiDigits: String {
    imeiNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
  }
  
  // Computed property to check if IMEI is valid (exactly 15 digits)
  private var isIMEIValid: Bool {
    imeiDigits.count == 15
  }
  
  // Computed property to format IMEI with dashes (format: XXX-XXXXX-XXXXX-XX)
  private var formattedIMEI: Binding<String> {
    Binding(
      get: {
        let digits = imeiDigits
        if digits.isEmpty {
          return ""
        }
        // Format as XXX-XXXXX-XXXXX-XX
        var formatted = ""
        for (index, char) in digits.enumerated() {
          if index == 3 || index == 8 || index == 13 {
            formatted += "-"
          }
          formatted += String(char)
          // Limit to 15 digits
          if index >= 14 {
            break
          }
        }
        return formatted
      },
      set: { newValue in
        // Only allow digits, remove dashes
        imeiNumber = newValue.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
      }
    )
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Header
        VStack(spacing: 16) {
          Text("Find out if your phone is compatible")
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)

          // IMEI Input
          TextField("XXX-XXXXX-XXXXX-XX", text: formattedIMEI)
            .keyboardType(.numberPad)
            .padding()
            .background(Color.white)
            .cornerRadius(8)
            .font(.body)
            .disabled(isCheckingCompatibility || showCompatibilityResult)

          // Check Compatibility Button (only show if check hasn't been performed yet)
          if !showCompatibilityResult {
            Button(action: {
              checkDeviceCompatibility()
            }) {
              HStack {
                if isCheckingCompatibility {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                } else {
                  Text("Check Compatibility")
                    .fontWeight(.semibold)
                }
              }
              .foregroundColor(.black)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 15)
              .background(isCheckingCompatibility || !isIMEIValid ? Color.gray : Color("AccentColor2"))
              .cornerRadius(8)
            }
            .disabled(isCheckingCompatibility || !isIMEIValid)
          }

          // Submit Button (only show if compatibility check passed)
          if let result = compatibilityResult, result.isCompatible {
            Button(action: {
              onSubmitIMEI?(imeiDigits, result.isCompatible)
              isPresented = false
            }) {
              Text("Submit & Next")
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color("AccentColor2"))
                .cornerRadius(8)
            }
          }

          // Add "Done" button that appears after check is performed if result is NOT compatible
          if showCompatibilityResult, let result = compatibilityResult, !result.isCompatible {
            Button(action: {
              // Pass result even if not compatible
              onSubmitIMEI?(imeiDigits, result.isCompatible)
              isPresented = false
            }) {
              Text("Done")
                .fontWeight(.semibold)
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(8)
            }
          }
        }
        .padding()
        .background(Color.black)

        // Compatibility Result Section
        if showCompatibilityResult, let result = compatibilityResult {
          VStack(spacing: 0) {
            // Main Result Card
            VStack(spacing: 0) {
              // Header with icon and title
              HStack(spacing: 12) {
                ZStack {
                  Circle()
                    .fill(result.isCompatible ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                    .frame(width: 60, height: 60)
                  Image(systemName: result.isCompatible ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.isCompatible ? .green : .red)
                    .font(.system(size: 32))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                  Text(result.isCompatible ? "Device Compatible" : "Device Not Compatible")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                  
                  if let deviceName = result.MARKETINGNAME ?? result.MODEL {
                    Text(deviceName)
                      .font(.subheadline)
                      .foregroundColor(.secondary)
                  }
                }
                
                Spacer()
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)
          }
        }

        // Instructions Section
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            Text("How to find your device's IMEI number")
              .font(.title2)
              .fontWeight(.bold)
              .padding(.top, 20)

            // Tab Selection
            HStack(spacing: 16) {
              Button(action: { selectedTab = 0 }) {
                Text("iOS")
                  .fontWeight(.medium)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 8)
                  .background(selectedTab == 0 ? Color("AccentColor2") : Color.gray.opacity(0.2))
                  .foregroundColor(selectedTab == 0 ? .black : .primary)
                  .cornerRadius(20)
              }

              Button(action: { selectedTab = 1 }) {
                Text("Android")
                  .fontWeight(.medium)
                  .padding(.horizontal, 20)
                  .padding(.vertical, 8)
                  .background(selectedTab == 1 ? Color("AccentColor2") : Color.gray.opacity(0.2))
                  .foregroundColor(selectedTab == 1 ? .black : .primary)
                  .cornerRadius(20)
              }

              Spacer()
            }

            // Instructions Text

            VStack(alignment: .leading, spacing: 12) {
              if selectedTab == 0 {
                // iOS Instructions
                Text(
                  "1. To find your IMEI, go to Settings, General, About. You'll find your IMEI there. Alternatively, enter *#06# on your device's dialer to bring up the IMEI. If you see two IMEI numbers, enter either one to check device compatibility."
                )
                .font(.body)
                .foregroundColor(.secondary)
              } else {
                // Android Instructions with video link
                Text(
                  "1. To find your IMEI, open your Phone app and dial *#06#. Your IMEI will appear on the screen. You can also find it in Settings > About Phone."
                )
                .font(.body)
                .foregroundColor(.secondary)

                Button(action: {
                  showVideoSheet = true
                }) {
                  HStack(spacing: 6) {
                    Image(systemName: "play.rectangle.fill")
                      .foregroundColor(.blue)
                    Text("Watch Video Guide")
                      .underline()
                      .foregroundColor(.blue)
                  }
                }
                .padding(.vertical, 8)
              }

              Divider()
                .padding(.vertical, 8)

              VStack(alignment: .leading, spacing: 8) {
                Text("Can't find your IMEI?")
                  .font(.headline)
                  .fontWeight(.semibold)

                Text(
                  "You can skip the compatibility check, but just a heads-up — we can't promise everything will run smoothly if your device isn't compatible. Your call, but don't say we didn't warn you."
                )
                .font(.body)
                .foregroundColor(.secondary)

                Button(action: {
                  // Pass nil when skipping (no IMEI entered, no check performed)
                  if !imeiDigits.isEmpty {
                    onSubmitIMEI?(imeiDigits, nil)
                  }
                  isPresented = false
                }) {
                  Text("Skip compatibility check")
                    .foregroundColor(.blue)
                    .font(.body)
                }
                .padding(.top, 4)
              }
            }

            Spacer(minLength: 40)
          }
          .padding(.horizontal)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            // When closing, pass the result if a check was performed
            if let result = compatibilityResult {
              onSubmitIMEI?(imeiDigits, result.isCompatible)
            } else if !imeiDigits.isEmpty {
              // If IMEI was entered but not checked, pass nil
              onSubmitIMEI?(imeiDigits, nil)
            }
            isPresented = false
          }
          .foregroundColor(Color("AccentColor2"))
        }
      }
    }
    .sheet(isPresented: $showVideoSheet) {
      IMEIVideoSheet()
    }
    .alert("Error Checking Compatibility", isPresented: $showErrorAlert) {
      Button("OK", role: .cancel) { }
    } message: {
      Text(compatibilityError ?? "An unknown error occurred")
    }
  }
  
  // MARK: - Helper Methods
  
  private func checkDeviceCompatibility() {
    // Validate IMEI (should already be validated by button state, but double-check)
    guard isIMEIValid else {
      compatibilityError = "Invalid IMEI. Must be exactly 15 digits."
      showErrorAlert = true
      return
    }
    
    isCheckingCompatibility = true
    compatibilityResult = nil
    compatibilityError = nil
    showCompatibilityResult = false
    
    // Get carrier from current order's plan
    getCarrierFromOrder { carrier in
      guard let carrier = carrier else {
        DispatchQueue.main.async {
          self.isCheckingCompatibility = false
          self.compatibilityError = "Unable to determine carrier. Please ensure you have selected a plan."
          self.showErrorAlert = true
        }
        return
      }
      
      // Check device compatibility
      VCareAPIManager.shared.checkDeviceCompatibility(
        imei: imeiDigits,
        carrier: carrier,
        agentId: "Sushil", // TODO: Get from user settings or configuration
        source: "API"
      ) { result in
        DispatchQueue.main.async {
          self.isCheckingCompatibility = false
          
          switch result {
          case .success(let compatibilityData):
            self.compatibilityResult = compatibilityData
            self.showCompatibilityResult = true
            
            // Store eSIM availability in view model if available
            if let viewModel = self.viewModel {
              viewModel.supportsESIM = compatibilityData.supportsESIM
              viewModel.supportsPhysicalSIM = compatibilityData.supportsPhysicalSIM
              print("✅ Stored eSIM support: \(compatibilityData.supportsESIM), Physical SIM support: \(compatibilityData.supportsPhysicalSIM)")
            }
            
          case .failure(let error):
            self.compatibilityError = error.localizedDescription
            self.showErrorAlert = true
          }
        }
      }
    }
  }
  
  private func getCarrierFromOrder(completion: @escaping (String?) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
      completion(nil)
      return
    }
    
    // Get current order ID from UserDefaults
    let orderId = UserDefaults.standard.string(forKey: "currentOrderId")
    
    let db = Firestore.firestore()
    let orderRef: DocumentReference
    
    if let orderId = orderId {
      orderRef = db.collection("users").document(userId).collection("orders").document(orderId)
    } else {
      // Fallback: get any pending order (without ordering to avoid index requirement)
      db.collection("users").document(userId)
        .collection("orders")
        .whereField("status", isEqualTo: "pending")
        .limit(to: 1)
        .getDocuments { snapshot, error in
          if let error = error {
            print("❌ Error fetching order: \(error.localizedDescription)")
            completion(nil)
            return
          }
          
          guard let doc = snapshot?.documents.first,
                let planId = doc.data()["plan_id"] as? Int else {
            completion(nil)
            return
          }
          
          self.getCarrierFromPlanId(planId: planId, completion: completion)
        }
      return
    }
    
    // Get order document
    orderRef.getDocument { snapshot, error in
      if let error = error {
        print("❌ Error fetching order: \(error.localizedDescription)")
        completion(nil)
        return
      }
      
      guard let data = snapshot?.data(),
            let planId = data["plan_id"] as? Int else {
        completion(nil)
        return
      }
      
      // Get carrier from plan
      self.getCarrierFromPlanId(planId: planId, completion: completion)
    }
  }
  
  private func getCarrierFromPlanId(planId: Int, completion: @escaping (String?) -> Void) {
    let db = Firestore.firestore()
    
    // Query all plan documents to find the one with matching plan_id
    db.collection("plans")
      .getDocuments { snapshot, error in
        if let error = error {
          print("❌ Error fetching plans: \(error.localizedDescription)")
          completion(nil)
          return
        }
        
        guard let documents = snapshot?.documents else {
          completion(nil)
          return
        }
        
        // Search through all plan documents
        for doc in documents {
          let data = doc.data()
          if let plansArray = data["plans"] as? [[String: Any]] {
            for planDict in plansArray {
              if let id = planDict["plan_id"] as? Int, id == planId,
                 let carrierArray = planDict["carrier"] as? [String],
                 let firstCarrier = carrierArray.first {
                completion(firstCarrier)
                return
              }
            }
          }
        }
        
        completion(nil)
      }
  }
}

// MARK: - Video Sheet View

struct IMEIVideoSheet: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationView {
      VStack {
        if let url = Bundle.main.url(forResource: "imei_android", withExtension: "mp4") {
          VideoPlayer(player: AVPlayer(url: url))
            .aspectRatio(contentMode: .fit)
            .cornerRadius(12)
            .padding()
        } else {
          Text(
            "Video not found. Make sure imei_android.mp4 is added to your app target and not inside Assets.xcassets."
          )
          .foregroundColor(.red)
        }
        Spacer()
      }
      .navigationTitle("IMEI Video Guide")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(action: { dismiss() }) {
            Image(systemName: "xmark")
              .imageScale(.large)
              .foregroundColor(.primary)
          }
        }
      }
    }
  }
}

struct IMEICheckView_Previews: PreviewProvider {
  static var previews: some View {
    IMEICheckView(isPresented: .constant(true), viewModel: nil)
  }
}

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct NumberSelectionView: View {
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onNext: () -> Void
  var onBack: (() -> Void)? = nil
  var onCancel: (() -> Void)? = nil
  var showNavigation: Bool = true  // New parameter to control navigation display
  
  @State private var isValidatingPortIn: Bool = false
  @State private var portInValidationStatus: String? = nil
  @State private var portInValidationError: String? = nil
  @State private var hasValidatedPortIn: Bool = false
  @State private var carrierFromOrder: String? = nil

  var body: some View {
    let contentView = VStack(spacing: 24) {
      // Header section unified
      OrderStepHeader(
        "Transfer your existing number or choose a new number"
      )
      .onAppear {
        // Get carrier from order when view appears (only if Existing is selected)
        if viewModel.numberType == "Existing" {
          getCarrierFromOrder { carrier in
            DispatchQueue.main.async {
              self.carrierFromOrder = carrier
              // If phone number is already entered, trigger validation
              if !self.viewModel.selectedPhoneNumber.isEmpty && carrier != nil {
                self.validatePortIn()
              }
            }
          }
        }
      }

      // Button section with styling similar to SimSelectionView
      VStack(spacing: 12) {
        Button(action: {
          viewModel.numberType = "Existing"
          // Get carrier from order when Existing is selected
          getCarrierFromOrder { carrier in
            DispatchQueue.main.async {
              self.carrierFromOrder = carrier
              // If phone number is already entered, trigger validation
              if !self.viewModel.selectedPhoneNumber.isEmpty && carrier != nil {
                self.validatePortIn()
              }
            }
          }
        }) {
          Text("Transfer Your Existing Number")
            .font(.system(size: 18, weight: .medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .stroke(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                  ),
                  lineWidth: 2
                )
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(
                      viewModel.numberType == "Existing"
                        ? LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                        : LinearGradient(
                          gradient: Gradient(colors: [Color.clear, Color.clear]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                    )
                )
            )
            .foregroundColor(viewModel.numberType == "Existing" ? .white : .primary)
        }

        Button(action: {
          viewModel.numberType = "New"
        }) {
          Text("Choose a New Number")
            .font(.system(size: 18, weight: .medium))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
              RoundedRectangle(cornerRadius: 25)
                .stroke(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                  ),
                  lineWidth: 2
                )
                .background(
                  RoundedRectangle(cornerRadius: 25)
                    .fill(
                      viewModel.numberType == "New"
                        ? LinearGradient(
                          gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                        : LinearGradient(
                          gradient: Gradient(colors: [Color.clear, Color.clear]),
                          startPoint: .leading,
                          endPoint: .trailing
                        )
                    )
                )
            )
            .foregroundColor(viewModel.numberType == "New" ? .white : .primary)
        }
      }
      .padding(.horizontal, 16)

      // Conditional content based on selection
      if viewModel.numberType == "Existing" {
        // Explanatory text similar to screenshot
        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .top, spacing: 8) {
            Text("•")
              .foregroundColor(.orange)
              .font(.system(size: 16, weight: .bold))
              .padding(.top, 2)

            Text(
              "To transfer your number, you’ll need your Account Number, Account Name, Account Address, and a Transfer PIN or password from your current carrier. Without a correct PIN/password, your carrier will not release your number. You can usually get the PIN by calling your carrier or via their app. Please have this information ready before tapping Next."
            )
            .font(.system(size: 15))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)

        VStack(alignment: .leading, spacing: 12) {
          Text("Enter your existing number:")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .padding(.top, 6)

          TextField(
            "(000) 000-0000",
            text: Binding(
              get: { formatPhoneNumber(viewModel.selectedPhoneNumber) },
              set: { newValue in
                // Remove all non-numeric characters
                let digits = newValue.filter { $0.isNumber }
                // Limit to 10 digits
                let newPhoneNumber = String(digits.prefix(10))
                
                // Only update if the number actually changed
                if newPhoneNumber != viewModel.selectedPhoneNumber {
                  viewModel.selectedPhoneNumber = newPhoneNumber
                  
                  // Reset validation when phone number changes (only if not currently validating)
                  if !isValidatingPortIn {
                    hasValidatedPortIn = false
                    portInValidationStatus = nil
                    portInValidationError = nil
                    
                    // Trigger validation if carrier is available and we have 10 digits
                    if digits.count == 10 && carrierFromOrder != nil {
                      // Use Task to debounce the validation call
                      Task {
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
                        await MainActor.run {
                          if !isValidatingPortIn && viewModel.selectedPhoneNumber.count == 10 {
                            validatePortIn()
                          }
                        }
                      }
                    }
                  }
                }
              }
            )
          )
          .font(.system(size: 16))
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                viewModel.selectedPhoneNumber.count == 10 ? Color.accentGold : Color(.systemGray3),
                lineWidth: viewModel.selectedPhoneNumber.count == 10 ? 2 : 1
              )
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color(.systemBackground))
              )
          )
          .keyboardType(.phonePad)
          .textContentType(.telephoneNumber)
          
          // Validation status indicator
          if isValidatingPortIn {
            HStack {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
              Text("Validating phone number...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.top, 8)
          } else if let status = portInValidationStatus {
            HStack {
              Image(systemName: status == "Eligible" ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status == "Eligible" ? .green : .red)
              Text(status == "Eligible" ? "Number is eligible for porting" : "Number is not eligible for porting")
                .font(.subheadline)
                .foregroundColor(status == "Eligible" ? .green : .red)
            }
            .padding(.top, 8)
          } else if let error = portInValidationError {
            HStack {
              Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
              Text(error)
                .font(.subheadline)
                .foregroundColor(.orange)
            }
            .padding(.top, 8)
          }
        }
        .padding(.horizontal, 16)
      }

      Spacer()
    }

    // Return either wrapped in navigation container or just the content
    if showNavigation {
      return AnyView(
        StepNavigationContainer(
          currentStep: 4,
          totalSteps: 6,
          nextButtonText: "Next Step",
          nextButtonDisabled: viewModel.numberType.isEmpty
            || (viewModel.numberType == "Existing" && (viewModel.selectedPhoneNumber.count != 10 || isValidatingPortIn || !hasValidatedPortIn)),
          nextButtonAction: {
            // Save number selection to orders collection
            viewModel.saveNumberSelection { success in
              if success {
                if let userId = viewModel.userId, let orderId = viewModel.orderId {
                  FirebaseOrderManager.shared.saveStepProgress(
                    userId: userId, orderId: orderId, step: 4)
                }
                // Continue to next step only if save was successful
                onNext()
              } else {
                print("Failed to save number selection")
              }
            }
          },
          backButtonAction: {
            if let onBack = onBack {
              onBack()
            }
          },
          cancelAction: onCancel
        ) {
          contentView
        }
      )
    } else {
      return AnyView(contentView)
    }
  }

  // Helper function to format phone number
  private func formatPhoneNumber(_ number: String) -> String {
    let digits = number.filter { $0.isNumber }

    if digits.count >= 10 {
      let area = String(digits.prefix(3))
      let exchange = String(digits.dropFirst(3).prefix(3))
      let number = String(digits.dropFirst(6).prefix(4))
      return "(\(area)) \(exchange)-\(number)"
    } else if digits.count >= 6 {
      let area = String(digits.prefix(3))
      let exchange = String(digits.dropFirst(3))
      return "(\(area)) \(exchange)"
    } else if digits.count >= 3 {
      let area = String(digits.prefix(3))
      let remaining = String(digits.dropFirst(3))
      return "(\(area)) \(remaining)"
    } else if digits.count > 0 {
      return "(\(digits)"
    }

    return digits
  }
  
  // MARK: - Helper Methods (same as IMEICheckView)
  
  private func getCarrierFromOrder(completion: @escaping (String?) -> Void) {
    guard let userId = Auth.auth().currentUser?.uid else {
      print("❌ getCarrierFromOrder: No user ID")
      completion(nil)
      return
    }
    
    // Get current order ID from UserDefaults
    let orderId = UserDefaults.standard.string(forKey: "currentOrderId")
    print("🔍 getCarrierFromOrder: userId=\(userId), orderId=\(orderId ?? "nil")")
    
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
        print("⚠️ Order document missing plan_id. Data: \(snapshot?.data() ?? [:])")
        completion(nil)
        return
      }
      
      print("✅ Found plan_id in order: \(planId)")
      // Get carrier from plan
      self.getCarrierFromPlanId(planId: planId, completion: completion)
    }
  }
  
  private func getCarrierFromPlanId(planId: Int, completion: @escaping (String?) -> Void) {
    print("🔍 getCarrierFromPlanId: Searching for plan_id=\(planId)")
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
          print("⚠️ No plan documents found")
          completion(nil)
          return
        }
        
        print("📋 Found \(documents.count) plan documents")
        // Search through all plan documents
        for doc in documents {
          let data = doc.data()
          if let plansArray = data["plans"] as? [[String: Any]] {
            for planDict in plansArray {
              if let id = planDict["plan_id"] as? Int, id == planId,
                 let carrierArray = planDict["carrier"] as? [String],
                 let firstCarrier = carrierArray.first {
                print("✅ Found carrier for plan_id \(planId): \(firstCarrier)")
                completion(firstCarrier)
                return
              }
            }
          }
        }
        
        print("⚠️ No carrier found for plan_id: \(planId)")
        completion(nil)
      }
  }
  
  private func validatePortIn() {
    // Don't validate if already validating or if required fields are missing
    guard !isValidatingPortIn,
          !viewModel.selectedPhoneNumber.isEmpty,
          viewModel.selectedPhoneNumber.count == 10 else {
      print("⚠️ Cannot validate: isValidatingPortIn=\(isValidatingPortIn), phoneNumber=\(viewModel.selectedPhoneNumber), count=\(viewModel.selectedPhoneNumber.count)")
      return
    }
    
    guard let carrier = carrierFromOrder else {
      print("⚠️ Cannot validate: carrier is nil. Attempting to fetch carrier from order...")
      // Try to get carrier if we don't have it yet
      getCarrierFromOrder { fetchedCarrier in
        DispatchQueue.main.async {
          self.carrierFromOrder = fetchedCarrier
          if let carrier = fetchedCarrier {
            print("✅ Carrier fetched: \(carrier)")
            // Retry validation
            self.validatePortIn()
          } else {
            print("❌ Failed to fetch carrier from order")
            self.portInValidationError = "Unable to determine carrier. Please ensure you have selected a plan."
          }
        }
      }
      return
    }
    
    print("🔄 Starting port-in validation for phone: \(viewModel.selectedPhoneNumber), carrier: \(carrier)")
    
    // Reset previous validation
    hasValidatedPortIn = false
    portInValidationStatus = nil
    portInValidationError = nil
    isValidatingPortIn = true
    
    // Get zip code (required for AT&T, use user's saved zip)
    let zipCode = viewModel.zip.isEmpty ? nil : viewModel.zip
    print("📦 Using zip code: \(zipCode ?? "none")")
    
    // Call the API with carrier from order
    VCareAPIManager.shared.validatePortIn(
      mdn: viewModel.selectedPhoneNumber,
      carrier: carrier,
      zipCode: zipCode,
      agentId: "Sushil", // TODO: Get from user settings or configuration
      source: "WEBSITE"
    ) { result in
      DispatchQueue.main.async {
        isValidatingPortIn = false
        
        switch result {
        case .success(let validationData):
          hasValidatedPortIn = true
          portInValidationStatus = validationData.PORTINSTATUS ?? validationData.description
          portInValidationError = nil
          
          // Log the result
          if let status = validationData.PORTINSTATUS {
            print("✅ Port-in validation successful: \(status)")
          }
          
        case .failure(let error):
          hasValidatedPortIn = false
          portInValidationStatus = nil
          portInValidationError = error.localizedDescription
          print("❌ Port-in validation failed: \(error.localizedDescription)")
        }
      }
    }
  }
}

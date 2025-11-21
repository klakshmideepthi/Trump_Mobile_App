import SwiftUI

struct BillingInfoView: View {
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onNext: () -> Void
  var onBack: (() -> Void)? = nil
  var onCancel: (() -> Void)? = nil

  @State private var creditCardNumber = ""
  @State private var expirationDate = ""
  @State private var cvv = ""
  @State private var sameAsCustomerAddress = true
  @State private var emergencyAddress = ""
  @State private var sameAsCustomerAddressEmergency = true
  @State private var showBroadbandFacts = false
  @State private var agreeE911 = false
  @State private var agreeRecurringCharge = false
  @State private var agreePrivacyTerms = false
  @State private var isSaving = false
  
  // Plan information state
  @State private var planName: String = "Telgoo5 Mobile Plan"
  @State private var planPrice: Double = 47.45
  @State private var isLoadingPlanInfo = false

  var body: some View {
    let stepNumber = 5
    let isNextDisabled = (!isFormValid || isSaving)

    return StepNavigationContainer(
      currentStep: stepNumber,
      nextButtonText: "Complete Order",
      nextButtonDisabled: isNextDisabled,
      nextButtonAction: { handleSubmitBilling() },
      backButtonAction: { onBack?() },
      cancelAction: onCancel
    ) {
      billingContent()
    }
    .onAppear {
      // Prefill local fields from view model if editing an existing order
      if creditCardNumber.isEmpty { creditCardNumber = viewModel.creditCardNumber }
      if expirationDate.isEmpty { expirationDate = viewModel.billingDetails }
      
      // Load plan information from order
      loadPlanInfo()
    }
  }

  private var isFormValid: Bool {
    creditCardNumber.replacingOccurrences(of: " ", with: "").count >= 15 &&
      expirationDate.count == 5 &&
      cvv.count >= 3 &&
      agreeE911 && agreeRecurringCharge && agreePrivacyTerms
  }
  
  // Load plan information from order document
  private func loadPlanInfo() {
    guard let orderId = viewModel.orderId else {
      return
    }
    
    isLoadingPlanInfo = true
    
    FirebaseOrderManager.shared.fetchOrderDocument(orderId: orderId) { result in
      DispatchQueue.main.async {
        isLoadingPlanInfo = false
        
        if case .success(let data) = result {
          // Extract plan information
          if let name = data["planName"] as? String {
            planName = name
          }
          
          // Handle planPrice - can be Int or Double
          if let price = data["planPrice"] as? Int {
            planPrice = Double(price)
          } else if let price = data["planPrice"] as? Double {
            planPrice = price
          } else if let amount = data["amount"] as? Double {
            planPrice = amount
          }
        }
      }
    }
  }
}

// MARK: - Helpers
private extension BillingInfoView {
  func handleSubmitBilling() {
    isSaving = true
    viewModel.creditCardNumber = creditCardNumber
    viewModel.billingDetails = expirationDate
    viewModel.saveBillingInfo { success in
      if success {
        if let userId = viewModel.userId, let orderId = viewModel.orderId {
          FirebaseOrderManager.shared.saveStepProgress(userId: userId, orderId: orderId, step: 5)
          
          // After payment is completed, call create_customer_prepaid_multiline API
          createCustomerOrder(userId: userId, orderId: orderId)
        } else {
          isSaving = false
          onNext()
        }
      } else {
        isSaving = false
        let err = viewModel.errorMessage ?? "Unknown error"
        DebugLogger.shared.log("Failed to save billing info: \(err)", category: "BillingInfo")
      }
    }
  }
  
  func createCustomerOrder(userId: String, orderId: String) {
    // Fetch order document to get enrollment_id, plan_id, and other data
    FirebaseOrderManager.shared.fetchOrderDocument(orderId: orderId) { result in
      DispatchQueue.main.async {
        switch result {
        case .success(let orderData):
          // Extract required data from order
          guard let enrollmentId = orderData["enrollment_id"] as? String else {
            print("❌ Missing enrollment_id in order document")
            self.isSaving = false
            // Continue to next step even if enrollment_id is missing
            self.onNext()
            return
          }
          
          // Get plan_id - can be Int or String
          var planId: Int?
          if let planIdInt = orderData["plan_id"] as? Int {
            planId = planIdInt
          } else if let planIdString = orderData["plan_id"] as? String, let planIdInt = Int(planIdString) {
            planId = planIdInt
          }
          
          guard let planId = planId else {
            print("❌ Missing plan_id in order document")
            self.isSaving = false
            self.onNext()
            return
          }
          
          // Get order_id from payment (if available)
          // Try different possible field names
          var paymentOrderId: Int?
          if let orderIdInt = orderData["payment_order_id"] as? Int {
            paymentOrderId = orderIdInt
          } else if let orderIdInt = orderData["order_id"] as? Int {
            paymentOrderId = orderIdInt
          } else if let orderIdString = orderData["payment_order_id"] as? String, let orderIdInt = Int(orderIdString) {
            paymentOrderId = orderIdInt
          } else if let orderIdString = orderData["order_id"] as? String, let orderIdInt = Int(orderIdString) {
            paymentOrderId = orderIdInt
          }
          
          // Determine activation type
          let activationType: String
          if self.viewModel.numberType == "Existing" {
            activationType = "PORTIN"
          } else {
            activationType = "NEWACTIVATION"
          }
          
          // Determine enrollment type (SHIPMENT or HANDOVER)
          let enrollmentType: String
          if self.viewModel.simType == "eSIM" {
            enrollmentType = "SHIPMENT"  // eSIM always uses SHIPMENT
          } else {
            // For physical SIM, check if customer has SIM (HANDOVER) or needs shipment
            enrollmentType = "SHIPMENT"  // Default to SHIPMENT for now
          }
          
          // Determine is_esim
          let isEsim = self.viewModel.simType == "eSIM" ? "Y" : "N"
          
          // Get carrier from order or use default
          let carrier = orderData["carrier"] as? String ?? "TMBRLY"
          
          // Build customer info dictionary
          var customerInfo: [String: Any] = [
            "activation_type": activationType,
            "enrollment_type": enrollmentType,
            "is_esim": isEsim,
            "carrier": carrier,
            "email": self.viewModel.email,
            "first_name": self.viewModel.firstName,
            "last_name": self.viewModel.lastName,
            "service_address_one": self.viewModel.street,
            "service_address_two": self.viewModel.aptNumber,
            "service_city": self.viewModel.city,
            "service_state": self.viewModel.state,
            "service_zip": self.viewModel.zip,
            "billing_address_one": self.viewModel.street,  // Use same as service for now
            "billing_address_two": self.viewModel.aptNumber,
            "billing_city": self.viewModel.city,
            "billing_state": self.viewModel.state,
            "billing_zip": self.viewModel.zip,
            "notify_bill_via_text": "Y",
            "notify_bill_via_email": "Y"
          ]
          
          // Add password if available
          if !self.viewModel.password.isEmpty {
            customerInfo["password"] = self.viewModel.password
          }
          
          // Add alternate phone number if available
          if !self.viewModel.phoneNumber.isEmpty {
            customerInfo["alternate_phone_number"] = self.viewModel.phoneNumber
          }
          
          // Add port-in information if activation type is PORTIN
          if activationType == "PORTIN" {
            customerInfo["port_current_carrier"] = self.viewModel.portInCurrentCarrier
            customerInfo["port_account_number"] = self.viewModel.portInAccountNumber
            customerInfo["port_account_password"] = self.viewModel.portInPin
            customerInfo["port_number"] = self.viewModel.selectedPhoneNumber
            
            // Port-in name (split if available)
            let portName = self.viewModel.portInAccountHolderName
            let portNameParts = portName.split(separator: " ", maxSplits: 1)
            if portNameParts.count >= 2 {
              customerInfo["port_first_name"] = String(portNameParts[0])
              customerInfo["port_last_name"] = String(portNameParts[1])
            } else if portNameParts.count == 1 {
              customerInfo["port_first_name"] = String(portNameParts[0])
              customerInfo["port_last_name"] = ""
            }
            
            // Use service address for port-in address (as per typical flow)
            customerInfo["port_address_one"] = self.viewModel.street
            customerInfo["port_address_two"] = self.viewModel.aptNumber
            customerInfo["port_city"] = self.viewModel.city
            customerInfo["port_state"] = self.viewModel.state
            customerInfo["port_zip_code"] = self.viewModel.zip
          }
          
          // Call create_customer_prepaid_multiline API
          print("🔄 Calling create_customer_prepaid_multiline API...")
          // Generate unique transaction ID for this API call
          let transactionId = VCareAPIManager.generateTransactionId(orderId: orderId, action: "CREATE")
          VCareAPIManager.shared.createCustomerPrepaidMultiline(
            enrollmentId: enrollmentId,
            orderId: paymentOrderId,
            planId: planId,
            customerInfo: customerInfo,
            agentId: "Sushil",  // TODO: Get from user settings or configuration
            source: "WEBSITE",
            externalTransactionId: transactionId
          ) { result in
            DispatchQueue.main.async {
              self.isSaving = false
              
              switch result {
              case .success(let response):
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("✅ CUSTOMER CREATED SUCCESSFULLY")
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                print("📋 API Response Details:")
                print("   Message: \(response.msg)")
                print("   Message Code: \(response.msg_code)")
                if let externalTxnId = response.external_transaction_id {
                  print("   External Transaction ID: \(externalTxnId)")
                }
                print("   Token: \(response.token.prefix(50))...")
                
                // Log line details
                if let lines = response.data, !lines.isEmpty {
                  print("   Number of Lines: \(lines.count)")
                  
                  for (index, lineResponse) in lines.enumerated() {
                    print("   ──────────────────────────────────────")
                    print("   Line \(index + 1):")
                    print("      Message: \(lineResponse.msg)")
                    print("      Message Code: \(lineResponse.msg_code)")
                    
                    if let lineData = lineResponse.data {
                      if let custId = lineData.cust_id {
                        print("      Customer ID: \(custId)")
                      }
                      if let customerId = lineData.customer_id {
                        print("      Customer ID (alt): \(customerId)")
                      }
                      if let enrollmentId = lineData.enrollment_id {
                        print("      Enrollment ID: \(enrollmentId)")
                      }
                      if let enrollmentType = lineData.enrollment_type {
                        print("      Enrollment Type: \(enrollmentType)")
                      }
                      if let mdn = lineData.mdn, !mdn.isEmpty {
                        print("      MDN (Phone Number): \(mdn)")
                      }
                      if let msid = lineData.msid, !msid.isEmpty {
                        print("      MSID: \(msid)")
                      }
                      if let msl = lineData.msl, !msl.isEmpty {
                        print("      MSL: \(msl)")
                      }
                      if let invoiceNumber = lineData.invoice_number, !invoiceNumber.isEmpty {
                        print("      Invoice Number: \(invoiceNumber)")
                      }
                    } else {
                      print("      ⚠️ No line data in response")
                    }
                  }
                } else {
                  print("   ⚠️ No lines data in response")
                }
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                // Log to DebugLogger
                var logMessage = "Customer created successfully: \(response.msg) (Code: \(response.msg_code))"
                if let lines = response.data, let firstLine = lines.first, let lineData = firstLine.data {
                  if let custId = lineData.cust_id {
                    logMessage += " | Customer ID: \(custId)"
                  }
                  if let mdn = lineData.mdn, !mdn.isEmpty {
                    logMessage += " | MDN: \(mdn)"
                  }
                }
                DebugLogger.shared.log(logMessage, category: "BillingInfo")
                
                // Save customer ID and other response data to order if needed
                if let lines = response.data, let firstLine = lines.first, let lineData = firstLine.data {
                  var updateData: [String: Any] = [:]
                  
                  if let custId = lineData.cust_id {
                    updateData["cust_id"] = custId
                    print("💾 Saving cust_id: \(custId) to order")
                  }
                  if let customerId = lineData.customer_id {
                    updateData["customer_id"] = customerId
                    print("💾 Saving customer_id: \(customerId) to order")
                  }
                  if let mdn = lineData.mdn, !mdn.isEmpty {
                    updateData["mdn"] = mdn
                    print("💾 Saving MDN: \(mdn) to order")
                  }
                  if let enrollmentId = lineData.enrollment_id {
                    updateData["enrollment_id"] = enrollmentId
                    print("💾 Saving enrollment_id: \(enrollmentId) to order")
                  }
                  
                  if !updateData.isEmpty {
                    FirebaseOrderManager.shared.saveStepProgress(
                      userId: userId,
                      orderId: orderId,
                      step: 5,
                      data: updateData
                    )
                    print("✅ Successfully saved customer data to order")
                  }
                }
                
                // Continue to next step
                self.onNext()
                
              case .failure(let error):
                print("❌ Failed to create customer: \(error.localizedDescription)")
                DebugLogger.shared.log("Failed to create customer: \(error.localizedDescription)", category: "BillingInfo")
                
                // Show error but continue to next step (order is saved locally)
                // You may want to show an alert to the user here
                self.onNext()
              }
            }
          }
          
        case .failure(let error):
          print("❌ Failed to fetch order document: \(error.localizedDescription)")
          DebugLogger.shared.log("Failed to fetch order document: \(error.localizedDescription)", category: "BillingInfo")
          self.isSaving = false
          // Continue to next step even if order fetch fails
          self.onNext()
        }
      }
    }
  }

  @ViewBuilder
  func billingContent() -> some View {
    VStack(spacing: 20) {
      headerSection()
      pricingSection()
      paymentSection()
      emergencyAddressSection()
      broadbandFactsSection()
      Spacer(minLength: 20)
    }
  }

  @ViewBuilder
  private func headerSection() -> some View {
    OrderStepHeader("Billing Information")
      .accessibilityAddTraits(.isHeader)
  }

  @ViewBuilder
  private func pricingSection() -> some View {
    VStack(spacing: 8) {
      // Plan Name
      HStack {
        Text("Plan")
          .font(.body)
        Spacer()
        Text(planName)
          .font(.body)
          .fontWeight(.medium)
          .foregroundColor(.primary)
      }
      
      // Plan Price
      HStack {
        Text("Plan Price")
          .font(.body)
        Spacer()
        Text("$\(String(format: "%.2f", planPrice))")
          .font(.body)
          .fontWeight(.medium)
      }

      // Calculate tax (7% - adjust as needed)
      let tax = planPrice * 0.07
      HStack {
        Text("Plan Tax")
          .font(.body)
        Spacer()
        Text("$\(String(format: "%.2f", tax))")
          .font(.body)
          .fontWeight(.medium)
      }

      Divider()

      // Total
      let total = planPrice + tax
      HStack {
        Text("Total")
          .font(.body)
          .fontWeight(.semibold)
        Spacer()
        Text("$\(String(format: "%.2f", total))")
          .font(.body)
          .fontWeight(.semibold)
      }
    }
    .padding()
    .background(Color.adaptiveSecondaryBackground)
    .cornerRadius(8)
  }

  @ViewBuilder
  private func paymentSection() -> some View {
    VStack(spacing: 15) {
      applePayButton()
      cardNumberRow()
      expiryCvvRow()
      sameAddressRow()
    }
  }

  @ViewBuilder
  private func applePayButton() -> some View {
    Button {
      // TODO: Implement Apple Pay
    } label: {
      HStack {
        Image(systemName: "applelogo")
        Text("Pay with Apple Pay")
      }
      .frame(maxWidth: .infinity)
      .padding(12)
      .background(Color.black)
      .foregroundColor(.white)
      .cornerRadius(8)
    }
  }

  @ViewBuilder
  private func cardNumberRow() -> some View {
      HStack {
      TextField("Card Number", text: $creditCardNumber)
        .padding(12)
        .background(Color.adaptiveBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(8)
        .keyboardType(.numberPad)
        .textContentType(.creditCardNumber)
        .onChange(of: creditCardNumber) { _, newValue in
          let cleaned = newValue.filter { $0.isNumber }
          creditCardNumber = String(cleaned.prefix(19)).chunkedCreditCard()
        }
        .accessibilityLabel("Card Number")

      Image(systemName: "creditcard")
        .foregroundColor(.gray)
        .padding(.leading, 8)
    }
  }

  @ViewBuilder
  private func expiryCvvRow() -> some View {
    HStack(spacing: 10) {
      TextField("MM/YY", text: $expirationDate)
        .padding(12)
        .background(Color.adaptiveBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(8)
        .keyboardType(.numberPad)
        .onChange(of: expirationDate) { _, newValue in
          let cleaned = newValue.filter { $0.isNumber }
          let limited = String(cleaned.prefix(4))
          if limited.count > 2 {
            let month = limited.prefix(2)
            let year = limited.suffix(from: limited.index(limited.startIndex, offsetBy: 2))
            expirationDate = month + "/" + year
          } else {
            expirationDate = limited
          }
        }
        .accessibilityLabel("Expiration Date")

      TextField("CVV", text: $cvv)
        .padding(12)
        .background(Color.adaptiveBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
        .cornerRadius(8)
        .keyboardType(.numberPad)
        .frame(maxWidth: 80)
        .textContentType(.creditCardSecurityCode)
        .privacySensitive() // Avoid showing CVV in recordings/snapshots
        .accessibilityLabel("Security Code")
    }
  }

  @ViewBuilder
  private func sameAddressRow() -> some View {
    HStack {
      Button(action: { sameAsCustomerAddress.toggle() }) {
        Image(systemName: sameAsCustomerAddress ? "checkmark.circle.fill" : "circle")
          .foregroundColor(sameAsCustomerAddress ? Color("AccentColor") : .gray)
      }
      Text("Same as Shipping Address")
        .font(.body)
      Spacer()
    }
  }

  @ViewBuilder
  private func emergencyAddressSection() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Emergency 911 Address (required for Wi‑Fi Calling)")
        .font(.headline)
        .fontWeight(.semibold)

      HStack {
        Button(action: { sameAsCustomerAddressEmergency.toggle() }) {
          Image(systemName: sameAsCustomerAddressEmergency ? "checkmark.circle.fill" : "circle")
        }
        .foregroundColor(sameAsCustomerAddressEmergency ? Color("AccentColor") : .gray)

        Text("Same as Shipping Address")
          .font(.body)
        Spacer()
      }

      if !sameAsCustomerAddressEmergency {
        TextField("Emergency Address", text: $emergencyAddress)
          .padding(12)
          .background(Color.adaptiveBackground)
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                LinearGradient(
                  gradient: Gradient(colors: [Color("AccentColor"), Color("AccentColor2")]),
                  startPoint: .leading,
                  endPoint: .trailing
                ),
                lineWidth: 2
              )
          )
          .cornerRadius(8)
      }

      AgreementRow(isOn: $agreeE911,
                   text: "I confirm the address provided is my E911 address for first responders in an emergency.")
      AgreementRow(isOn: $agreeRecurringCharge,
                   text: "I authorize Telgoo5 Mobile LLC to charge my card on a recurring basis. You can cancel any time to stop future charges.")
      AgreementRow(isOn: $agreePrivacyTerms,
                   text: "I agree to the Privacy Policy and Terms of Use.")
    }
    .padding()
    .background(Color.adaptiveSecondaryBackground)
    .cornerRadius(8)
  }

  @ViewBuilder
  private func broadbandFactsSection() -> some View {
    VStack(spacing: 10) {
      HStack {
        Text("BROADBAND FACTS")
          .font(.headline)
          .fontWeight(.bold)

        Spacer()

        Button(action: {
          withAnimation(.easeInOut(duration: 0.3)) { showBroadbandFacts.toggle() }
        }) {
          HStack(spacing: 4) {
            Image(systemName: "info.circle")
              .font(.caption)
            Image(systemName: showBroadbandFacts ? "chevron.up" : "chevron.down")
              .font(.caption)
          }
          .foregroundColor(Color("AccentColor"))
        }
      }

      if showBroadbandFacts {
        VStack(spacing: 15) {
          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
              Text("Mobile Broadband Consumer Disclosure")
                .font(.subheadline)
                .fontWeight(.semibold)
              Text("Monthly Price: $47.45")
                .font(.caption)
              Text("Not an introductory rate and does not require a contract.")
                .font(.caption)
                .foregroundColor(.gray)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 5) {
              Text("Speeds Provided with Plan")
                .font(.subheadline)
                .fontWeight(.semibold)
              Text("Typical Download: 10-50 Mbps")
                .font(.caption)
              Text("Typical Upload Speed: 1-10 Mbps")
                .font(.caption)
              Text("Typical Latency: 19-37 ms")
                .font(.caption)
            }
          }

          Divider()

          HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
              Text("Provider Monthly Fees")
                .font(.subheadline)
                .fontWeight(.semibold)
              Text("One-Time Fee: $0")
                .font(.caption)
              Text("Device Connection Charge: $0")
                .font(.caption)
              Text("Early Termination Fee: $0")
                .font(.caption)
              Text("Government Taxes: Varies by Location")
                .font(.caption)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 5) {
              Text("Unlimited Data Included with Monthly Price")
                .font(.subheadline)
                .fontWeight(.semibold)
              Text("With first 20GB at high speed")
                .font(.caption)
              Text("Charges for Additional Data Usage: $0")
                .font(.caption)
              Text("*Residential, non-commercial use only.")
                .font(.caption)
                .foregroundColor(.gray)
                .italic()
                .padding(.top, 5)
            }
          }
        }
        .padding()
        .background(Color.adaptiveSecondaryBackground)
        .cornerRadius(8)
        .transition(.opacity.combined(with: .scale))
      }
    }
  }
}
private struct AgreementRow: View {
  @Binding var isOn: Bool
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Button(action: { isOn.toggle() }) {
        Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
          .foregroundColor(isOn ? Color("AccentColor") : .gray)
      }
      Text(text)
        .font(.caption)
        .foregroundColor(.gray)
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.top, 5)
  }
}

private extension String {
  func chunkedCreditCard() -> String {
    let digits = self
    var parts: [String] = []
    var start = digits.startIndex
    while start < digits.endIndex {
      let end = digits.index(start, offsetBy: 4, limitedBy: digits.endIndex) ?? digits.endIndex
      parts.append(String(digits[start..<end]))
      start = end
    }
    return parts.joined(separator: " ")
  }
}

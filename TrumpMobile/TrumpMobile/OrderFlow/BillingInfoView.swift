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
    }
  }

  private var isFormValid: Bool {
    creditCardNumber.replacingOccurrences(of: " ", with: "").count >= 15 &&
      expirationDate.count == 5 &&
      cvv.count >= 3 &&
      agreeE911 && agreeRecurringCharge && agreePrivacyTerms
  }
}

// MARK: - Helpers
private extension BillingInfoView {
  func handleSubmitBilling() {
    isSaving = true
    viewModel.creditCardNumber = creditCardNumber
    viewModel.billingDetails = expirationDate
    viewModel.saveBillingInfo { success in
      isSaving = false
      if success {
        if let userId = viewModel.userId, let orderId = viewModel.orderId {
          FirebaseOrderManager.shared.saveStepProgress(userId: userId, orderId: orderId, step: 5)
        }
        onNext()
      } else {
        let err = viewModel.errorMessage ?? "Unknown error"
        DebugLogger.shared.log("Failed to save billing info: \(err)", category: "BillingInfo")
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
      HStack {
        Text("Plan Price")
          .font(.body)
        Spacer()
        Text("$47.45")
          .font(.body)
          .fontWeight(.medium)
      }

      HStack {
        Text("Plan Tax")
          .font(.body)
        Spacer()
        Text("$3.34")
          .font(.body)
          .fontWeight(.medium)
      }

      Divider()

      HStack {
        Text("Total")
          .font(.body)
          .fontWeight(.semibold)
        Spacer()
        Text("$50.79")
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

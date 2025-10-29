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

  var body: some View {
    StepNavigationContainer(
      currentStep: 5,
      nextButtonText: "Complete Order",
      nextButtonDisabled: creditCardNumber.isEmpty || expirationDate.isEmpty || cvv.isEmpty
        || !agreeE911 || !agreeRecurringCharge || !agreePrivacyTerms,
      nextButtonAction: {
        // Log billing information submission
        DebugLogger.shared.logUserAction(
          "Submitting Billing Information",
          for: [
            "firstName": viewModel.firstName,
            "lastName": viewModel.lastName,
            "email": viewModel.email,
            "creditCardNumber": String(creditCardNumber.prefix(4)) + "****",  // Only log first 4 digits for security
            "expirationDate": expirationDate,
            "userId": viewModel.userId ?? "nil",
            "agreeE911": agreeE911 ? "Yes" : "No",
            "agreeRecurringCharge": agreeRecurringCharge ? "Yes" : "No",
            "agreePrivacyTerms": agreePrivacyTerms ? "Yes" : "No",
          ])

        viewModel.creditCardNumber = creditCardNumber
        viewModel.billingDetails = expirationDate
        viewModel.saveBillingInfo { success in
          if success {
            DebugLogger.shared.log(
              "Billing info saved successfully for user \(viewModel.firstName) \(viewModel.lastName)",
              category: "BillingInfo")
            if let userId = viewModel.userId, let orderId = viewModel.orderId {
              FirebaseOrderManager.shared.saveStepProgress(
                userId: userId, orderId: orderId, step: 5)
            }
            onNext()
          } else {
            print("Failed to save billing information")
            DebugLogger.shared.log(
              "Failed to save billing info: \(viewModel.errorMessage ?? "Unknown error")",
              category: "BillingInfo")
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
      ScrollView {
        VStack(spacing: 20) {
          // Header
          Text("BILLING INFORMATION")
            .font(.title2)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 10)

          Text(
            "Please enter the serial number (IMEI) of your phone to see if it can work on our network before proceeding to enter the Billing Information"
          )
          .font(.caption)
          .foregroundColor(.gray)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

          // Pricing Information
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
          .background(Color(.systemGray6))
          .cornerRadius(8)

          // Payment Information
          VStack(spacing: 15) {
            HStack {
              TextField("Credit Card Number", text: $creditCardNumber)
                .padding(12)
                .background(Color(.systemBackground))
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
                .keyboardType(.numberPad)

              Image(systemName: "creditcard")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            }

            HStack(spacing: 10) {
              TextField("Expiration Date (MM/YY)", text: $expirationDate)
                .padding(12)
                .background(Color(.systemBackground))
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
                .keyboardType(.numberPad)

              TextField("CVV", text: $cvv)
                .padding(12)
                .background(Color(.systemBackground))
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
                .keyboardType(.numberPad)
                .frame(maxWidth: 80)
            }

            HStack {
              Button(action: {
                sameAsCustomerAddress.toggle()
              }) {
                Image(systemName: sameAsCustomerAddress ? "checkmark.circle.fill" : "circle")
                  .foregroundColor(sameAsCustomerAddress ? Color("AccentColor") : .gray)
              }
              Text("Same as Customer Address")
                .font(.body)
              Spacer()
            }
          }

          // Emergency 911 Address Section
          VStack(alignment: .leading, spacing: 10) {
            Text("Emergency 911 Address (Required For Wifi Calling)")
              .font(.headline)
              .fontWeight(.semibold)

            HStack {
              Button(action: {
                sameAsCustomerAddressEmergency.toggle()
              }) {
                Image(
                  systemName: sameAsCustomerAddressEmergency ? "checkmark.circle.fill" : "circle"
                )
                .foregroundColor(sameAsCustomerAddressEmergency ? Color("AccentColor") : .gray)
              }
              Text("Same as Customer Address")
                .font(.body)
              Spacer()
            }

            if !sameAsCustomerAddressEmergency {
              TextField("Emergency Address", text: $emergencyAddress)
                .padding(12)
                .background(Color(.systemBackground))
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

            HStack(alignment: .top, spacing: 8) {
              Button(action: {
                agreeE911.toggle()
              }) {
                Image(systemName: agreeE911 ? "checkmark.circle.fill" : "circle")
                  .foregroundColor(agreeE911 ? Color("AccentColor") : .gray)
              }
              Text(
                "I confirm that the address provided is my E911 address, which will be used by first responders in case of an emergency."
              )
              .font(.caption)
              .foregroundColor(.gray)
              .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 5)

            HStack(alignment: .top, spacing: 8) {
              Button(action: {
                agreeRecurringCharge.toggle()
              }) {
                Image(systemName: agreeRecurringCharge ? "checkmark.circle.fill" : "circle")
                  .foregroundColor(agreeRecurringCharge ? Color("AccentColor") : .gray)
              }
              Text(
                "By checking this box, you authorize Telgoo5 Mobile LLC to charge your card on a recurring basis. You can cancel the service at any time to stop future charges."
              )
              .font(.caption)
              .foregroundColor(.gray)
              .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 5)

            HStack(alignment: .top, spacing: 8) {
              Button(action: {
                agreePrivacyTerms.toggle()
              }) {
                Image(systemName: agreePrivacyTerms ? "checkmark.circle.fill" : "circle")
                  .foregroundColor(agreePrivacyTerms ? Color("AccentColor") : .gray)
              }
              Text(
                "You are acknowledging your agreement to our Privacy Policy and Terms of Use by creating an account or logging into your Telgoo5 Mobile account."
              )
              .font(.caption)
              .foregroundColor(.gray)
              .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 5)
          }
          .padding()
          .background(Color(.systemGray6))
          .cornerRadius(8)

          // Broadband Facts Section
          VStack(spacing: 10) {
            HStack {
              Text("BROADBAND FACTS")
                .font(.headline)
                .fontWeight(.bold)

              Spacer()

              Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                  showBroadbandFacts.toggle()
                }
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
                // Mobile Broadband Consumer Disclosure
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

                // Provider Monthly Fees
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
              .background(Color(.systemGray6))
              .cornerRadius(8)
              .transition(.opacity.combined(with: .scale))
            }
          }

          Spacer(minLength: 20)
        }
      }
    }
    .onAppear {
      // Prefill local fields from view model if editing an existing order
      if creditCardNumber.isEmpty { creditCardNumber = viewModel.creditCardNumber }
      if expirationDate.isEmpty { expirationDate = viewModel.billingDetails }
    }
  }
}

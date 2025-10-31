import SwiftUI

private enum ActiveSheet: Identifiable {
  case qr
  case activation
  case success

  var id: Int {
    switch self {
    case .qr: return 0
    case .activation: return 1
    case .success: return 2
    }
  }
}

struct SIMSetupView: View {
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onNext: () -> Void
  var onBack: (() -> Void)? = nil
  var onCancel: (() -> Void)? = nil
  var showNavigation: Bool = true

  @State private var activeSheet: ActiveSheet?
  @State private var simTypeSnapshot: String = ""
  @State private var isForThisDeviceSnapshot: Bool = false

  var body: some View {
    let contentView = VStack(spacing: 24) {
      simSetupSection
      Spacer()
    }
    .padding(.horizontal, 20)
    .background(Color.adaptiveBackground)
    .sheet(item: $activeSheet) { sheet in
      switch sheet {
      case .qr:
        QRCodeView(
          viewModel: viewModel,
          onReturn: {
            completeAndReturn()
          }
        )
      case .activation:
        CompletionSheetView(
          title: "Activated on This Device",
          message: "Your eSIM has been successfully activated on this device."
        ) {
          completeAndReturn()
        }
      case .success:
        CompletionSheetView(
          title: "Order Complete",
          message: "Your order is complete. Your physical SIM will be shipped shortly."
        ) {
          completeAndReturn()
        }
      }
    }
    .onAppear {
      simTypeSnapshot = viewModel.simType
      isForThisDeviceSnapshot = viewModel.isForThisDevice
    }

    // Return either wrapped in navigation container or just the content
    if showNavigation {
      return AnyView(
        StepNavigationContainer(
          currentStep: 6,
          totalSteps: 6,
          nextButtonText: "Complete Order",
          nextButtonDisabled: false,
          nextButtonAction: {
            if viewModel.simType == "eSIM" {
              // Snapshot for sheet rendering before viewmodel is reset!
              simTypeSnapshot = viewModel.simType
              isForThisDeviceSnapshot = viewModel.isForThisDevice
              if viewModel.isForThisDevice {
                activeSheet = .activation
              } else {
                activeSheet = .qr
              }
            } else {
              // Physical SIM: show success sheet; complete on return
              activeSheet = .success
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

  private var simSetupSection: some View {
    VStack(spacing: 20) {
      OrderStepHeader("SIM Card Setup")

      if !viewModel.selectedPhoneNumber.isEmpty {
        Text("NUMBER: \(viewModel.selectedPhoneNumber)")
          .font(.subheadline)
          .foregroundColor(Color.accentGold)
          .fontWeight(.medium)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity, alignment: .center)
      }

      if viewModel.simType == "eSIM" {
        esimSetupView
      } else {
        physicalSimSetupView
      }

      // Show port-in summary if applicable
      if isPortInFlow {
        portInSummarySection
      }
    }
  }

  private var successTitle: String {
    if simTypeSnapshot == "eSIM", isForThisDeviceSnapshot {
      return "Activated on This Device"
    }
    return "Order Complete"
  }

  private var successMessage: String {
    if simTypeSnapshot == "eSIM" {
      if isForThisDeviceSnapshot {
        return "Your eSIM has been successfully activated on this device."
      } else {
        return "Your eSIM order is complete. Use the QR code on your other device to activate."
      }
    } else {
      return "Your order is complete. Your physical SIM will be shipped shortly."
    }
  }

  private var isPortInFlow: Bool {
    viewModel.numberType == "Existing" || viewModel.numberType.lowercased().contains("existing")
      || viewModel.numberType.lowercased().contains("transfer")
  }

  private var portInSummarySection: some View {
    VStack(spacing: 16) {
      Divider()
        .background(Color.adaptiveBorder)
        .padding(.vertical, 8)

      VStack(spacing: 8) {
        HStack {
          Image(systemName: "checkmark.circle.fill")
            .font(.title3)
            .foregroundColor(Color.accentGold)
          Text("Number Transfer Information Received")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color.adaptiveText)
          Spacer()
        }
      }

      VStack(spacing: 12) {
        HStack {
          Text("Phone Number:")
            .fontWeight(.medium)
            .foregroundColor(Color.adaptiveText)
          Spacer()
          Text(viewModel.selectedPhoneNumber)
            .foregroundColor(Color.accentGold)
        }

        HStack {
          Text("Current Carrier:")
            .fontWeight(.medium)
            .foregroundColor(Color.adaptiveText)
          Spacer()
          Text(viewModel.portInCurrentCarrier)
            .foregroundColor(Color.adaptiveSecondaryText)
        }

        HStack {
          Text("Account Holder:")
            .fontWeight(.medium)
            .foregroundColor(Color.adaptiveText)
          Spacer()
          Text(viewModel.portInAccountHolderName)
            .foregroundColor(Color.adaptiveSecondaryText)
        }
      }
      .padding()
      .background(Color.accentGold.opacity(0.1))
      .cornerRadius(12)

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Image(systemName: "info.circle.fill")
            .foregroundColor(Color.accentGold)
          Text("Next Steps:")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(Color.adaptiveText)
        }

        VStack(alignment: .leading, spacing: 4) {
          Text("• Your number transfer will begin processing after order completion")
            .foregroundColor(Color.adaptiveText)
          Text("• Keep your current phone active during the transfer")
            .foregroundColor(Color.adaptiveText)
          Text("• Transfer typically completes within 4-24 hours")
            .foregroundColor(Color.adaptiveText)
        }
        .font(.caption)
      }
      .padding()
      .background(Color.accentGold.opacity(0.05))
      .cornerRadius(12)
    }
  }

  private var esimSetupView: some View {
    VStack(spacing: 16) {
      VStack(spacing: 8) {
        Image(systemName: "simcard.2")
          .font(.system(size: 50))
          .foregroundColor(Color.accentGold)

        Text("eSIM Activation")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(Color.adaptiveText)
      }

      Text("Is this eSIM for this device or another device?")
        .multilineTextAlignment(.center)
        .foregroundColor(Color.adaptiveSecondaryText)

      VStack(spacing: 12) {
        Button(action: {
          viewModel.isForThisDevice = true
          viewModel.showQRCode = false
        }) {
          HStack {
            Image(systemName: viewModel.isForThisDevice ? "checkmark.circle.fill" : "circle")
              .foregroundColor(
                viewModel.isForThisDevice ? Color.accentGold : Color.adaptiveSecondaryText)
            Text("This Device")
              .fontWeight(.medium)
              .foregroundColor(Color.adaptiveText)
            Spacer()
            if viewModel.isForThisDevice {
              Image(systemName: "iphone")
                .foregroundColor(Color.accentGold)
            }
          }
          .padding()
          .background(
            viewModel.isForThisDevice
              ? Color.accentGold.opacity(0.1) : Color.adaptiveSecondaryBackground
          )
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                viewModel.isForThisDevice ? Color.accentGold : Color.adaptiveBorder, lineWidth: 1.5)
          )
        }
        .buttonStyle(PlainButtonStyle())

        Button(action: {
          viewModel.isForThisDevice = false
          viewModel.showQRCode = true
          activeSheet = .qr
        }) {
          HStack {
            Image(systemName: !viewModel.isForThisDevice ? "checkmark.circle.fill" : "circle")
              .foregroundColor(
                !viewModel.isForThisDevice ? Color.accentGold : Color.adaptiveSecondaryText)
            Text("Another Device")
              .fontWeight(.medium)
              .foregroundColor(Color.adaptiveText)
            Spacer()
            if !viewModel.isForThisDevice {
              Image(systemName: "qrcode")
                .foregroundColor(Color.accentGold)
            }
          }
          .padding()
          .background(
            !viewModel.isForThisDevice
              ? Color.accentGold.opacity(0.1) : Color.adaptiveSecondaryBackground
          )
          .cornerRadius(12)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                !viewModel.isForThisDevice ? Color.accentGold : Color.adaptiveBorder, lineWidth: 1.5
              )
          )
        }
        .buttonStyle(PlainButtonStyle())
      }

      if viewModel.isForThisDevice {
        VStack(spacing: 8) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(Color.accentGold)
            .font(.title2)

          Text("eSIM will be activated directly on this device after order completion.")
            .font(.caption)
            .foregroundColor(Color.adaptiveSecondaryText)
            .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.accentGold.opacity(0.1))
        .cornerRadius(8)
      }
    }
  }

  private var physicalSimSetupView: some View {
    VStack(spacing: 24) {
      // Header
      VStack(spacing: 10) {
        Image(systemName: "shippingbox.fill")
          .font(.system(size: 48))
          .foregroundColor(Color.accentGold)

        Text("Physical SIM Card")
          .font(.headline)
          .fontWeight(.semibold)
          .foregroundColor(Color.adaptiveText)

        Text("Shipping will be initiated")
          .font(.title3)
          .fontWeight(.semibold)
          .foregroundColor(Color.accentGold)
          .multilineTextAlignment(.center)
      }

      // Address card
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 8) {
          Image(systemName: "truck.box.fill")
            .foregroundColor(Color.accentGold)
          Text("Your physical SIM card will be shipped to:")
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(Color.adaptiveText)
          Spacer(minLength: 0)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("\(viewModel.firstName) \(viewModel.lastName)")
          Text(viewModel.street)
          if !viewModel.aptNumber.isEmpty {
            Text("Apt \(viewModel.aptNumber)")
          }
          Text("\(viewModel.city), \(viewModel.state) \(viewModel.zip)")
        }
        .font(.subheadline)
        .foregroundColor(Color.adaptiveText)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.adaptiveSecondaryBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color.adaptiveBorder, lineWidth: 1)
        )
        .cornerRadius(12)
      }

      // Delivery info card
      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 8) {
          Image(systemName: "clock.fill")
            .foregroundColor(Color.accentGold2)
          Text("Delivery Information:")
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(Color.adaptiveText)
          Spacer(minLength: 0)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("• Shipping within 2–3 business days")
          Text("• Tracking information will be emailed to you")
          Text("• Activate your SIM once received")
        }
        .font(.caption)
        .foregroundColor(Color.adaptiveText)
      }
      .padding(14)
      .background(Color.accentGold2.opacity(0.08))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.accentGold2.opacity(0.25), lineWidth: 1)
      )
      .cornerRadius(12)
    }
  }

  private func completeOrder() {
    viewModel.isLoading = true

    viewModel.completeOrder { orderSuccess in
      DispatchQueue.main.async {
        viewModel.isLoading = false
        print("DEBUG: completeOrder -> orderSuccess: \(orderSuccess)")
        if orderSuccess {
          let effectiveSimType = simTypeSnapshot.isEmpty ? viewModel.simType : simTypeSnapshot
          print("completeOrder success, simType: \(effectiveSimType), isForThisDevice: \(viewModel.isForThisDevice)")
          if effectiveSimType == "eSIM" {
            activeSheet = .success
          } else {
            onNext()
          }
        } else {
          // Handle error - you might want to show an alert
          print("Failed to complete order")
        }
      }
    }
  }

  private func completeAndReturn() {
    viewModel.isLoading = true
    viewModel.completeOrder { orderSuccess in
      DispatchQueue.main.async {
        viewModel.isLoading = false
        if orderSuccess {
          activeSheet = nil
          onNext()
        } else {
          print("Failed to complete order")
        }
      }
    }
  }
}

struct QRCodeView: View {
  @Environment(\.dismiss) private var dismiss
  let viewModel: UserRegistrationViewModel
  let onReturn: (() -> Void)?

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Text("eSIM QR Code")
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(Color.adaptiveText)

        Text("Scan this QR code with your other device to activate the eSIM")
          .multilineTextAlignment(.center)
          .foregroundColor(Color.adaptiveSecondaryText)
          .padding(.horizontal)

        // QR Code placeholder - you'll need to generate actual QR code
        VStack(spacing: 16) {
          RoundedRectangle(cornerRadius: 16)
            .fill(Color.adaptiveBackground)
            .frame(width: 250, height: 250)
            .overlay(
              VStack(spacing: 8) {
                Image("QR")
                  .resizable()
                  .scaledToFit()
                  .frame(width: 180, height: 180)
              }
            )
            .overlay(
              RoundedRectangle(cornerRadius: 16)
                .stroke(Color.adaptiveBorder, lineWidth: 1)
            )
            .shadow(color: Color.adaptiveText.opacity(0.1), radius: 8, x: 0, y: 4)

          Text("Order #: \(viewModel.orderId ?? "N/A")")
            .font(.caption)
            .foregroundColor(Color.adaptiveSecondaryText)
        }

        VStack(alignment: .leading, spacing: 12) {
          Text("Setup Instructions:")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(Color.adaptiveText)

          VStack(alignment: .leading, spacing: 8) {
            InstructionStep(number: 1, text: "Open Camera app on your other device")
            InstructionStep(number: 2, text: "Point camera at this QR code")
            InstructionStep(number: 3, text: "Tap the notification to add cellular plan")
            InstructionStep(number: 4, text: "Follow the prompts to complete activation")
          }
        }
        .padding()
        .background(Color.accentGold.opacity(0.1))
        .cornerRadius(12)

        Button(action: {
          onReturn?()
          dismiss()
        }) {
          Text("Return to Dashboard")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentGold)
            .foregroundColor(.white)
            .cornerRadius(12)
        }

        Spacer()
      }
      .padding()
      .background(Color.adaptiveBackground)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar { }
    }
  }
}

struct InstructionStep: View {
  let number: Int
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Text("\(number)")
        .font(.caption)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .frame(width: 20, height: 20)
        .background(Color.accentGold)
        .clipShape(Circle())

      Text(text)
        .font(.subheadline)
        .multilineTextAlignment(.leading)
        .foregroundColor(Color.adaptiveText)

      Spacer()
    }
  }
}

struct CompletionSheetView: View {
  @Environment(\.dismiss) private var dismiss
  let title: String
  let message: String
  let onReturn: () -> Void

  var body: some View {
    NavigationView {
      VStack(spacing: 24) {
        Image(systemName: "checkmark.seal.fill")
          .font(.system(size: 56))
          .foregroundColor(Color.accentGold)

        Text(title)
          .font(.title)
          .fontWeight(.bold)
          .foregroundColor(Color.adaptiveText)

        Text(message)
          .multilineTextAlignment(.center)
          .foregroundColor(Color.adaptiveSecondaryText)
          .padding(.horizontal)

        Spacer()

        Button(action: {
          onReturn()
          dismiss()
        }) {
          Text("Return to Dashboard")
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentGold)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
      }
      .padding()
      .background(Color.adaptiveBackground)
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

#Preview {
  SIMSetupView(
    viewModel: UserRegistrationViewModel(),
    onNext: {}
  )
}

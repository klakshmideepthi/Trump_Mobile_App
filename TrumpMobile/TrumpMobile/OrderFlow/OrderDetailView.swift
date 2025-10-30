import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct OrderDetailView: View {
  let orderId: String
  @State private var orderDetail: OrderDetail?
  @State private var isLoading = true
  @State private var errorMessage: String?
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var navigationState: NavigationState

  private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  var body: some View {
    NavigationView {
      ScrollView {
        if isLoading {
          ProgressView("Loading order details...")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 100)
        } else if let errorMessage = errorMessage {
          VStack {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundColor(.red)
            Text("Error")
              .font(.title2)
              .fontWeight(.semibold)
            Text(errorMessage)
              .multilineTextAlignment(.center)
              .padding()
          }
          .padding()
        } else if let order = orderDetail {
          VStack(spacing: 20) {
            // Order Header
            orderHeaderSection(order)

            // Personal Information
            personalInfoSection(order)

            // Address Information
            addressInfoSection(order)

            // Device Information
            deviceInfoSection(order)

            // Service Information
            serviceInfoSection(order)

            // Billing Information
            billingInfoSection(order)

            // Timestamps
            timestampsSection(order)
          }
          .padding()
        }
      }
      .navigationTitle("Order Details")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          HStack(spacing: 16) {
            Button("Edit") { onEditTapped() }
              .disabled(isLoading)
            Button("Done") { dismiss() }
          }
        }
      }
    }
    .onAppear {
      loadOrderDetails()
    }
  }

  private func onEditTapped() {
    isLoading = true
    FirebaseOrderManager.shared.fetchOrderDocument(orderId: orderId) { result in
      DispatchQueue.main.async {
        self.isLoading = false
        switch result {
        case .failure(let error):
          self.errorMessage = error.localizedDescription
        case .success(let data):
          let status =
            (data["status"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
          let step = data["currentStep"] as? Int ?? 1

          if status == "completed" {
            AppStoreLinking.openYouTube()
            return
          }

          // Resume editing this order at its saved step
          navigationState.resumeOrder(orderId: orderId, at: max(1, min(6, step)))
          // Mark that we've applied resume for this order so it won't be reapplied unexpectedly
          navigationState.lastAppliedResumeForOrderId = orderId
          // Dismiss on the next runloop cycle to avoid SwiftUI double-pop navigation behavior
          DispatchQueue.main.async {
            dismiss()
          }
        }
      }
    }
  }

  // Centralized deep link logic lives in AppStoreLinking

  private func orderHeaderSection(_ order: OrderDetail) -> some View {
    VStack(spacing: 8) {
      HStack {
        Text("Order ID")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
        Text(order.orderId)
          .font(.caption)
          .fontWeight(.medium)
      }

      HStack {
        Text("Status")
          .font(.headline)
        Spacer()
        Text(order.status.capitalized)
          .font(.headline)
          .foregroundColor(statusColor(order.status))
          .padding(.horizontal, 12)
          .padding(.vertical, 4)
          .background(statusColor(order.status).opacity(0.1))
          .cornerRadius(8)
      }
    }
    .padding()
    .background(Color.adaptiveSecondaryBackground)
    .cornerRadius(10)
  }

  private func personalInfoSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Personal Information") {
      detailRow(label: "Name", value: "\(order.firstName) \(order.lastName)")
      detailRow(label: "Email", value: order.email)
      if !order.phoneNumber.isEmpty {
        detailRow(label: "Phone", value: order.phoneNumber)
      }
    }
  }

  private func addressInfoSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Address Information") {
      detailRow(label: "Street", value: order.street)
      if !order.aptNumber.isEmpty {
        detailRow(label: "Apt/Unit", value: order.aptNumber)
      }
      detailRow(label: "City", value: order.city)
      detailRow(label: "State", value: order.state)
      detailRow(label: "ZIP", value: order.zip)
      detailRow(label: "Country", value: order.country)
    }
  }

  private func deviceInfoSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Device Information") {
      detailRow(label: "Brand", value: order.deviceBrand)
      detailRow(label: "Model", value: order.deviceModel)
      detailRow(label: "Compatible", value: order.deviceIsCompatible ? "Yes" : "No")
      detailRow(label: "For This Device", value: order.isForThisDevice ? "Yes" : "No")
      if !order.imei.isEmpty {
        detailRow(label: "IMEI", value: order.imei)
      }
    }
  }

  private func serviceInfoSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Service Information") {
      detailRow(label: "Number Type", value: order.numberType)
      if !order.selectedPhoneNumber.isEmpty {
        detailRow(label: "Selected Number", value: order.selectedPhoneNumber)
      }
      detailRow(label: "SIM Type", value: order.simType)
      detailRow(label: "Port-in Skipped", value: order.portInSkipped ? "Yes" : "No")
      detailRow(label: "Show QR Code", value: order.showQRCode ? "Yes" : "No")
    }
  }

  private func billingInfoSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Billing Information") {
      if !order.billingDetails.isEmpty {
        detailRow(label: "Billing Details", value: order.billingDetails)
      }
      if !order.creditCardNumber.isEmpty {
        detailRow(label: "Credit Card", value: maskCreditCard(order.creditCardNumber))
      }
    }
  }

  private func timestampsSection(_ order: OrderDetail) -> some View {
    sectionCard(title: "Order Timeline") {
      detailRow(label: "Created", value: dateFormatter.string(from: order.createdAt))
      detailRow(label: "Last Updated", value: dateFormatter.string(from: order.updatedAt))
      if let completionDate = order.orderCompletionDate {
        detailRow(
          label: "Completed", value: dateFormatter.string(from: completionDate))
      }
    }
  }

  private func sectionCard<Content: View>(
    title: String, @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.headline)
        .fontWeight(.semibold)

      VStack(spacing: 8) {
        content()
      }
    }
    .padding()
    .background(Color.adaptiveBackground)
    .cornerRadius(10)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }

  private func detailRow(label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.subheadline)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)
        .multilineTextAlignment(.trailing)
    }
  }

  private func statusColor(_ status: String) -> Color {
    switch status.lowercased() {
    case "completed":
      return .green
    case "pending":
      return .orange
    case "cancelled":
      return .red
    case "processing":
      return .blue
    default:
      return .secondary
    }
  }

  private func maskCreditCard(_ cardNumber: String) -> String {
    if cardNumber.count <= 4 {
      return cardNumber
    }
    let lastFour = String(cardNumber.suffix(4))
    let masked = String(repeating: "*", count: max(0, cardNumber.count - 4))
    return masked + lastFour
  }

  private func loadOrderDetails() {
    guard let userId = Auth.auth().currentUser?.uid else {
      DispatchQueue.main.async {
        self.isLoading = false
        self.errorMessage = "User not authenticated"
      }
      return
    }

    let db = Firestore.firestore()

    db.collection("users").document(userId)
      .collection("orders").document(orderId)
      .getDocument { document, error in
        DispatchQueue.main.async {
          self.isLoading = false

          if let error = error {
            self.errorMessage = "Failed to load order details: \(error.localizedDescription)"
            return
          }

          guard let document = document, document.exists,
            let data = document.data()
          else {
            self.errorMessage = "Order not found"
            return
          }

          self.orderDetail = OrderDetail(from: data)
        }
      }
  }
}

#Preview {
  OrderDetailView(orderId: "sample-order-id")
}

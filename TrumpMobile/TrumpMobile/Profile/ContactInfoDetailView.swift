import SwiftUI

struct ContactInfoDetailView: View {
  @StateObject private var viewModel = ContactInfoDetailViewModel()
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack(spacing: 0) {
      // Custom header with Close button
      HStack {
        Text("Contact Information")
          .font(.title2.bold())
          .foregroundColor(.primary)
        Spacer()
        Button("Close") { dismiss() }
          .foregroundColor(.accentColor)
          .font(.body)
      }
      .padding(.horizontal, 16)
      .padding(.top, 20)
      .padding(.bottom, 8)
      .background(Color(.systemBackground))

      // Profile Card
      VStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.accentGold, Color.accentGold2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 90, height: 90)
          Image(systemName: "person.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 48, height: 48)
            .foregroundColor(.white)
        }
        Text("\(viewModel.contactInfo.firstName) \(viewModel.contactInfo.lastName)")
          .font(.title2.bold())
          .foregroundColor(.primary)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 24)
      .background(Color(.systemBackground))

      // Info Sections as iOS grouped list
      List {
        Section(header: Text("Contact Information")) {
          ProfileRow(
            label: "Name",
            value: "\(viewModel.contactInfo.firstName) \(viewModel.contactInfo.lastName)")
          ProfileRow(label: "Email", value: viewModel.contactInfo.email)
          ProfileRow(label: "Phone", value: viewModel.contactInfo.phoneNumber)
        }
        Section(header: Text("Shipping Address")) {
          ProfileRow(label: "Street Address", value: viewModel.shippingAddress.street)
          ProfileRow(label: "Apt/Suite", value: viewModel.shippingAddress.aptNumber)
          ProfileRow(label: "City", value: viewModel.shippingAddress.city)
          ProfileRow(label: "State", value: viewModel.shippingAddress.state)
          ProfileRow(label: "ZIP Code", value: viewModel.shippingAddress.zip)
        }
      }
      .listStyle(.insetGrouped)
      .background(Color(.systemGroupedBackground))
    }
    .background(Color(.systemGroupedBackground).ignoresSafeArea())
    .navigationBarHidden(true)
    .onAppear {
      viewModel.loadContactInfo()
    }
    .alert("Error", isPresented: $viewModel.showError) {
      Button("OK") {}
    } message: {
      Text(viewModel.errorMessage)
    }
  }
}

struct ProfileRow: View {
  let label: String
  let value: String

  var body: some View {
    HStack {
      Text(label)
        .foregroundColor(.secondary)
      Spacer()
      Text(value)
        .foregroundColor(.primary)
        .multilineTextAlignment(.trailing)
    }
  }
}

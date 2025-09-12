import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ContactInfoDetailView: View {
    @StateObject private var viewModel = ContactInfoDetailViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.isLoading {
                        ProgressView("Loading contact information...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        contactInfoSection
                        shippingAddressSection
                    }
                }
                .padding()
            }
            .navigationTitle("Contact Information")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.accentColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: ContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {
                        // Reload data after editing
                        viewModel.loadContactInfo()
                    })) {
                        Text("Edit")
                            .foregroundColor(.accentColor)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            viewModel.loadContactInfo()
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CONTACT INFORMATION")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.trumpText)
            
            VStack(spacing: 12) {
                ContactInfoRow(title: "Name", value: "\(viewModel.contactInfo.firstName) \(viewModel.contactInfo.lastName)")
                ContactInfoRow(title: "Email", value: viewModel.contactInfo.email)
                ContactInfoRow(title: "Phone", value: viewModel.contactInfo.phoneNumber)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private var shippingAddressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SHIPPING ADDRESS")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(Color.trumpText)
            
            VStack(spacing: 12) {
                ContactInfoRow(title: "Street Address", value: viewModel.shippingAddress.street)
                if !viewModel.shippingAddress.aptNumber.isEmpty {
                    ContactInfoRow(title: "Apt/Suite", value: viewModel.shippingAddress.aptNumber)
                }
                ContactInfoRow(title: "City", value: viewModel.shippingAddress.city)
                ContactInfoRow(title: "State", value: viewModel.shippingAddress.state)
                ContactInfoRow(title: "ZIP Code", value: viewModel.shippingAddress.zip)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct ContactInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value.isEmpty ? "Not provided" : value)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    ContactInfoDetailView()
}

import CoreLocation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI

struct NewUserContactInfoView: View {
  @ObservedObject var viewModel: UserRegistrationViewModel
  var onNext: () -> Void
  
  @State private var isLoading = false
  @State private var errorMessage: String? = nil
  @StateObject private var locationManager = LocationManager()
  @State private var showLocationAlert = false
  @State private var didPromptSettings = false
  @State private var locationError: String? = nil
  @State private var useLocation = false
  @State private var isAutofillingLocation = false
  @State private var autofillTimeoutTask: DispatchWorkItem? = nil

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()
      
      VStack(spacing: 0) {
        // Header
        AppHeader {
          Image("Trump_Mobile_logo_gold")
            .resizable()
            .aspectRatio(80.0/23.0, contentMode: .fit)
            .frame(height: 25)
            .clipped()
          Spacer()
        }
        
        ScrollView {
          VStack(alignment: .center, spacing: 20) {
            if isLoading {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
                .padding(.top, 8)
            }
            
            if let message = errorMessage {
              Text(message)
                .foregroundColor(message.contains("success") ? .green : .red)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
            
            if !isLoading {
              // Contact Information Section
              VStack(alignment: .center, spacing: 12) {
                Text("CONTACT INFORMATION")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(Color.trumpText)
                  .multilineTextAlignment(.center)
                
                TextField("First Name", text: $viewModel.firstName)
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                
                TextField("Last Name", text: $viewModel.lastName)
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                
                TextField(
                  "(000) 000-0000",
                  text: Binding(
                    get: { formatPhoneNumber(viewModel.phoneNumber) },
                    set: { newValue in
                      let digits = newValue.filter { $0.isNumber }
                      viewModel.phoneNumber = String(digits.prefix(10))
                    }
                  )
                )
                  .font(.system(size: 16))
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(
                        viewModel.phoneNumber.count == 10 ? Color.accentGold : Color(.systemGray4),
                        lineWidth: viewModel.phoneNumber.count == 10 ? 2 : 1
                      )
                  )
                  .keyboardType(.phonePad)
                  .textContentType(.telephoneNumber)
                
                TextField("Email", text: $viewModel.email)
                  .padding()
                  .background(Color(.systemGray6))
                  .foregroundColor(.secondary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                  .keyboardType(.emailAddress)
                  .textInputAutocapitalization(.never)
                  .autocorrectionDisabled(true)
                  .disabled(true) // Email is not editable
              }
              
              // Shipping Address Section
              VStack(alignment: .center, spacing: 12) {
                Text("SHIPPING ADDRESS")
                  .font(.title2)
                  .fontWeight(.bold)
                  .foregroundColor(Color.trumpText)
                  .multilineTextAlignment(.center)
                
                Button(action: {
                  useLocation.toggle()
                  if useLocation {
                    if locationManager.authorizationStatus == .denied {
                      didPromptSettings = true
                    } else {
                      showLocationAlert = true
                    }
                  }
                }) {
                  HStack {
                    Image(systemName: useLocation ? "checkmark.square" : "square")
                      .foregroundColor(.accentColor)
                    Text("Use My Location to autofill address")
                      .foregroundColor(.primary)
                    if isAutofillingLocation || locationManager.isFetchingLocation {
                      ProgressView()
                        .scaleEffect(0.8)
                        .padding(.leading, 4)
                    }
                  }
                  .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                
                TextField("Street Address", text: $viewModel.street)
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                
                TextField("Apt, Suite, etc. (optional)", text: $viewModel.aptNumber)
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                
                TextField("City", text: $viewModel.city)
                  .padding()
                  .background(Color(.systemBackground))
                  .foregroundColor(.primary)
                  .cornerRadius(8)
                  .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(Color(.systemGray4), lineWidth: 1)
                  )
                
                HStack(spacing: 15) {
                  TextField("State", text: $viewModel.state)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                  
                  TextField("Zip Code", text: $viewModel.zip)
                    .padding()
                    .background(Color(.systemBackground))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .keyboardType(.numberPad)
                }
              }
            }
            
            Spacer(minLength: 20)
          }
          .padding(.horizontal, 30)
          .padding(.top, 20)
        }
        
        // Fixed bottom button
        BottomActionBar {
          PrimaryGradientButton(
            title: "Continue",
            isDisabled: viewModel.firstName.isEmpty || viewModel.lastName.isEmpty
              || viewModel.phoneNumber.count != 10 || isLoading,
            action: {
              saveContactInfo()
            }
          )
        }
      }
      .disabled(locationManager.isFetchingLocation)
      .overlay {
        if locationManager.isFetchingLocation {
          ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 12) {
              ProgressView()
              Text("Getting your location...")
                .font(.footnote)
                .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
              .ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
          .transition(.opacity)
        }
      }
    }
    .navigationBarHidden(true)
    .onAppear {
      // Set the authenticated user's email if not already set
      if viewModel.email.isEmpty {
        viewModel.email = Auth.auth().currentUser?.email ?? ""
      }
      // Auto-fill name from email if available
      autofillNameFromEmail()
    }
    .alert("Allow Location Access?", isPresented: $showLocationAlert) {
      Button("Allow") {
        locationManager.requestLocation()
        isAutofillingLocation = true
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("We can use your location to autofill your shipping address.")
    }
    .alert("Location Permission Denied", isPresented: $didPromptSettings) {
      Button("Open Settings") {
        openAppSettings()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Location access is denied. Please enable it in Settings to autofill your address.")
    }
    .onReceive(
      NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
    ) { _ in
      locationManager.authorizationStatus = CLLocationManager.authorizationStatus()
    }
    .onChange(of: locationManager.userLocation) { location in
      autofillTimeoutTask?.cancel()
      isAutofillingLocation = false
      guard let location = location else { return }
      let geocoder = CLGeocoder()
      geocoder.reverseGeocodeLocation(location) { placemarks, error in
        if let placemark = placemarks?.first {
          viewModel.street = placemark.thoroughfare ?? ""
          viewModel.city = placemark.locality ?? ""
          viewModel.state = placemark.administrativeArea ?? ""
          viewModel.zip = placemark.postalCode ?? ""
          viewModel.aptNumber = placemark.subThoroughfare ?? ""
        } else if let error = error {
          locationError = error.localizedDescription
        }
      }
    }
    .onChange(of: showLocationAlert) { show in
      if show {
        isAutofillingLocation = true
        autofillTimeoutTask?.cancel()
        let task = DispatchWorkItem {
          isAutofillingLocation = false
          locationError = "Location lookup timed out. Please try again."
        }
        autofillTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: task)
      } else {
        isAutofillingLocation = false
        autofillTimeoutTask?.cancel()
      }
    }
    .onChange(of: locationManager.authorizationStatus) { status in
      if useLocation && isAutofillingLocation
        && (status == .authorizedWhenInUse || status == .authorizedAlways)
      {
        isAutofillingLocation = true
        autofillTimeoutTask?.cancel()
        let task = DispatchWorkItem {
          isAutofillingLocation = false
          locationError = "Location lookup timed out. Please try again."
        }
        autofillTimeoutTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 8, execute: task)
        locationManager.requestLocation()
      }
    }
    .alert("Location Error", isPresented: .constant(locationError != nil)) {
      Button("OK") { locationError = nil }
    } message: {
      Text(locationError ?? "")
    }
  }
  
  private func formatPhoneNumber(_ number: String) -> String {
    let digits = number.filter { $0.isNumber }
    if digits.count >= 10 {
      let area = String(digits.prefix(3))
      let exchange = String(digits.dropFirst(3).prefix(3))
      let num = String(digits.dropFirst(6).prefix(4))
      return "(\(area)) \(exchange)-\(num)"
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
  
  private func autofillNameFromEmail() {
    // Auto-fill name from Firebase Auth display name if available
    if viewModel.firstName.isEmpty || viewModel.lastName.isEmpty {
      if let displayName = Auth.auth().currentUser?.displayName {
        let nameParts = displayName.split(separator: " ")
        if viewModel.firstName.isEmpty, let first = nameParts.first {
          viewModel.firstName = String(first)
        }
        if viewModel.lastName.isEmpty, nameParts.count > 1 {
          viewModel.lastName = nameParts.dropFirst().joined(separator: " ")
        }
      }
    }
  }
  
  private func saveContactInfo() {
    guard let userId = viewModel.userId ?? Auth.auth().currentUser?.uid else {
      errorMessage = "User ID not available. Please log in again."
      return
    }
    
    viewModel.userId = userId
    isLoading = true
    errorMessage = nil
    
    // Get the authenticated user's email
    let authenticatedEmail = Auth.auth().currentUser?.email ?? ""
    let emailToSave = viewModel.email.isEmpty ? authenticatedEmail : viewModel.email
    
    // Create contact data
    let contactData: [String: Any] = [
      "userId": userId,
      "firstName": viewModel.firstName,
      "lastName": viewModel.lastName,
      "phoneNumber": viewModel.phoneNumber,
      "email": emailToSave,
      "updatedAt": FieldValue.serverTimestamp(),
    ]
    
    // Create shipping address data
    let shippingAddressData: [String: Any] = [
      "userId": userId,
      "street": viewModel.street,
      "aptNumber": viewModel.aptNumber,
      "zip": viewModel.zip,
      "city": viewModel.city,
      "state": viewModel.state,
      "updatedAt": FieldValue.serverTimestamp(),
    ]
    
    let dispatchGroup = DispatchGroup()
    var saveErrors: [String] = []
    
    // Save to contactInfo collection
    dispatchGroup.enter()
    FirebaseManager.shared.saveContactInfo(userId: userId, contactData: contactData) {
      success, error in
      if !success {
        if let error = error {
          saveErrors.append("Failed to save contact info: \(error.localizedDescription)")
        } else {
          saveErrors.append("Failed to save contact info")
        }
      }
      dispatchGroup.leave()
    }
    
    // Save to shippingAddress collection
    dispatchGroup.enter()
    FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: shippingAddressData) {
      success, error in
      if !success {
        if let error = error {
          saveErrors.append("Failed to save shipping address: \(error.localizedDescription)")
        } else {
          saveErrors.append("Failed to save shipping address")
        }
      }
      dispatchGroup.leave()
    }
    
    // When all save operations complete
    dispatchGroup.notify(queue: .main) {
      self.isLoading = false
      
      if saveErrors.isEmpty {
        print("✅ Successfully saved contact information")
        onNext()
      } else {
        self.errorMessage = saveErrors.joined(separator: "; ")
      }
    }
  }
}

struct NewUserContactInfoView_Previews: PreviewProvider {
  static var previews: some View {
    NewUserContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {})
  }
}


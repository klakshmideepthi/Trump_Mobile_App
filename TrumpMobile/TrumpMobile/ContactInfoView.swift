import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct ContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onCancel: (() -> Void)? = nil
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
        StepNavigationContainer(
            currentStep: 1,
            nextButtonText: "Next Step",
            nextButtonDisabled: viewModel.firstName.isEmpty || viewModel.lastName.isEmpty || viewModel.phoneNumber.isEmpty || isLoading,
            nextButtonAction: {
                print("📲 Next button tapped in ContactInfoView")
                // This is the critical fix - make sure we save before continuing
                if let userId = viewModel.userId ?? Auth.auth().currentUser?.uid {
                    print("👤 Using userId: \(userId)")
                    viewModel.userId = userId  // Ensure userId is set
                    // Save contact info before continuing
                    viewModel.saveContactInfo { success in
                        if success {
                            print("✅ Contact info saved successfully, calling onNext")
                            onNext()
                        } else {
                            print("❌ Failed to save contact info: \(viewModel.errorMessage ?? "Unknown error")")
                            errorMessage = viewModel.errorMessage ?? "Failed to save contact information"
                        }
                    }
                } else {
                    print("❌ No userId available")
                    errorMessage = "User ID not available. Please log in again."
                }
            },
            backButtonAction: {},
            cancelAction: onCancel,
            disableBackButton: true,
            disableCancelButton: false
        ) {
            VStack(alignment: .center, spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                        .padding(.top, 8)
                }
                
                // Always show status message if available
                if let message = errorMessage {
                    Text(message)
                        .foregroundColor(message.contains("success") ? .green : .red)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Form fields
                if !isLoading {
                    // Contact Information Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("CONTACT INFORMATION")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.trumpText)
                    
                        // Input fields with improved styling
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
                        
                        TextField("Phone Number", text: $viewModel.phoneNumber)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .keyboardType(.phonePad)
                        
                        TextField("Email", text: $viewModel.email)
                            .padding()
                            .background(Color(.systemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    
                    // Customer Address Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SHIPPING ADDRESS")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(Color.trumpText)
                            .padding(.top, 8)


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
                        
                                        // Checkbox-style 'Use My Location' below all fields
                                        Button(action: {
                                            useLocation.toggle()
                                            if useLocation {
                                                // If denied, prompt to open settings
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
                                                if isAutofillingLocation {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                        .padding(.leading, 4)
                                                }
                                            }
                                            .padding(.vertical, 8)
                                        }
                                        .buttonStyle(.plain)
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Set the authenticated user's email if not already set
            if viewModel.email.isEmpty {
                viewModel.email = Auth.auth().currentUser?.email ?? ""
            }
            loadUserData()
        }
        .alert("Allow Location Access?", isPresented: $showLocationAlert) {
            Button("Allow") {
                locationManager.requestLocation()
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
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Refresh status when returning from settings
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
                // When user agrees to autofill, start loading and timeout
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
            if useLocation && isAutofillingLocation &&
                (status == .authorizedWhenInUse || status == .authorizedAlways) {
                // Start loading and timeout again
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
    
    func loadUserData() {
        guard let user = Auth.auth().currentUser else { return }
        
        isLoading = true
        let db = Firestore.firestore()
        let dispatchGroup = DispatchGroup()
        
        // For step 1 (contact info), ALWAYS load from subcollections, not from orders
        // This ensures we always get the user's saved contact info and shipping address
        // but don't pre-fill order-specific data from previous orders
        
        // Load contact info from subcollection
        dispatchGroup.enter()
        db.collection("users").document(user.uid).collection("contactInfo").document("primary").getDocument { document, error in
            defer { dispatchGroup.leave() }
            
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.viewModel.firstName = data["firstName"] as? String ?? self.viewModel.firstName
                    self.viewModel.lastName = data["lastName"] as? String ?? self.viewModel.lastName
                    self.viewModel.phoneNumber = data["phoneNumber"] as? String ?? self.viewModel.phoneNumber
                    self.viewModel.email = data["email"] as? String ?? self.viewModel.email
                }
            }
        }
        
        // Load shipping address from subcollection
        dispatchGroup.enter()
        db.collection("users").document(user.uid).collection("shippingAddress").document("primary").getDocument { document, error in
            defer { dispatchGroup.leave() }
            
            if let document = document, document.exists, let data = document.data() {
                DispatchQueue.main.async {
                    self.viewModel.street = data["street"] as? String ?? self.viewModel.street
                    self.viewModel.aptNumber = data["aptNumber"] as? String ?? self.viewModel.aptNumber
                    self.viewModel.city = data["city"] as? String ?? self.viewModel.city
                    self.viewModel.state = data["state"] as? String ?? self.viewModel.state
                    self.viewModel.zip = data["zip"] as? String ?? self.viewModel.zip
                }
            }
        }
        
        // Once all data loading attempts are completed
        dispatchGroup.notify(queue: .main) {
            self.isLoading = false

            // Autofill from Gmail if first/last name are empty
            if self.viewModel.firstName.isEmpty || self.viewModel.lastName.isEmpty {
                if let displayName = Auth.auth().currentUser?.displayName {
                    let nameParts = displayName.split(separator: " ")
                    if self.viewModel.firstName.isEmpty, let first = nameParts.first {
                        self.viewModel.firstName = String(first)
                    }
                    if self.viewModel.lastName.isEmpty, nameParts.count > 1 {
                        self.viewModel.lastName = nameParts.dropFirst().joined(separator: " ")
                    }
                }
            }
        }
    }
}

struct ContactInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ContactInfoView(viewModel: UserRegistrationViewModel(), onNext: {}, onCancel: {})
    }
}
import SwiftUI
import MapKit
import FirebaseAuth
import FirebaseFirestore
import CoreLocation

struct AddressInfoSheet: View {
  let currentAddress: String
  let zipCode: String
  let onChangeAddress: () -> Void
  
  @Environment(\.dismiss) var dismiss
  
  // Address fields
  @State private var streetAddress: String = ""
  @State private var aptNumber: String = ""
  @State private var zipCodeField: String = ""
  @State private var city: String = ""
  @State private var state: String = ""
  
  // UI state
  @State private var isEditing = false
  @State private var isLoadingCityState = false
  @State private var isLoading = false
  @State private var isLoadingLocation = false
  @State private var errorMessage: String? = nil
  
  // Location manager
  @StateObject private var locationManager = LocationManager()
  
  // Map camera position
  @State private var cameraPosition: MapCameraPosition = .region(
    MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
      span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
  )
  
  // Map annotation coordinate
  @State private var annotationCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
  
  var body: some View {
    NavigationView {
      ZStack {
        ScrollView {
          VStack(spacing: 0) {
            // Map Section
            Map(position: $cameraPosition) {
              Annotation("", coordinate: annotationCoordinate) {
                Image(systemName: "mappin.circle.fill")
                  .foregroundColor(.red)
                  .font(.system(size: 30))
              }
            }
            .mapStyle(.standard)
            .frame(height: 200)
            
            // Address Form
            VStack(alignment: .leading, spacing: 20) {
              // Use Current Location Button
              Button(action: {
                useCurrentLocation()
              }) {
                HStack {
                  Image(systemName: "location.fill")
                    .foregroundColor(.white)
                  Text("Use My Current Location")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                  
                  if isLoadingLocation {
                    ProgressView()
                      .progressViewStyle(CircularProgressViewStyle(tint: .white))
                      .scaleEffect(0.8)
                      .padding(.leading, 8)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                  LinearGradient(
                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                    startPoint: .leading,
                    endPoint: .trailing
                  )
                )
                .cornerRadius(10)
              }
              .disabled(isLoadingLocation || !isEditing)
              .opacity(isEditing ? 1.0 : 0.6)
              
              // Street Address
              VStack(alignment: .leading, spacing: 4) {
                Text("Street address")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                TextField("Street address", text: $streetAddress)
                  .padding()
                  .background(isEditing ? Color(.systemGray6) : Color(.systemGray5))
                  .cornerRadius(8)
                  .foregroundColor(isEditing ? .primary : .secondary)
                  .disabled(!isEditing)
                  .opacity(isEditing ? 1.0 : 0.6)
                  .onChange(of: streetAddress) { _, _ in
                    if isEditing && !streetAddress.isEmpty && !city.isEmpty && !state.isEmpty {
                      // Debounce map updates - only update after a short delay
                      Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await MainActor.run {
                          updateMapLocation()
                        }
                      }
                    }
                  }
              }
              
              // Apt, floor, suite, etc
              VStack(alignment: .leading, spacing: 4) {
                Text("Apt, floor, suite, etc (optional)")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                TextField("Apt, floor, suite, etc (optional)", text: $aptNumber)
                  .padding()
                  .background(isEditing ? Color(.systemGray6) : Color(.systemGray5))
                  .cornerRadius(8)
                  .foregroundColor(isEditing ? .primary : .secondary)
                  .disabled(!isEditing)
                  .opacity(isEditing ? 1.0 : 0.6)
              }
              
              
              // ZIP code and City/State
              VStack(alignment: .leading, spacing: 4) {
                Text("ZIP code (required)")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
                HStack(spacing: 12) {
                  TextField("ZIP code", text: $zipCodeField)
                    .padding()
                    .background(isEditing ? Color(.systemGray6) : Color(.systemGray5))
                    .cornerRadius(8)
                    .foregroundColor(isEditing ? .primary : .secondary)
                    .disabled(!isEditing)
                    .opacity(isEditing ? 1.0 : 0.6)
                    .keyboardType(.numberPad)
                    .onChange(of: zipCodeField) { oldValue, newValue in
                      // Limit to 5 digits
                      if newValue.count > 5 {
                        zipCodeField = String(newValue.prefix(5))
                      }
                      // Auto-fill city and state when ZIP code is complete
                      if isEditing && newValue.count == 5 && newValue.allSatisfy({ $0.isNumber }) {
                        fetchCityState(zipCode: newValue)
                      }
                    }
                  
                  if !city.isEmpty && !state.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                      Text("\(city), \(state)")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    }
                    .padding(.leading, 8)
                  }
                  
                  if isLoadingCityState {
                    ProgressView()
                      .scaleEffect(0.8)
                  }
                }
              }
              
              // Error message
              if let errorMessage = errorMessage {
                Text(errorMessage)
                  .font(.caption)
                  .foregroundColor(.red)
                  .padding(.horizontal)
              }
              
              // Delete address link
              if isEditing && !streetAddress.isEmpty {
                Button(action: {
                  deleteAddress()
                }) {
                  Text("Delete address")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                .padding(.top, 8)
              }
            }
            .padding()
            .padding(.bottom, 100) // Space for bottom button
          }
        }
        
        // Bottom button - fixed at bottom
        VStack {
          Spacer()
          Button(action: {
            if isEditing {
              saveAddress()
            } else {
              isEditing = true
            }
          }) {
            Text(isEditing ? "Save Address" : "Edit Address")
              .fontWeight(.semibold)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 15)
              .foregroundColor(.white)
              .background(
                LinearGradient(
                  gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .cornerRadius(10)
          }
          .padding(.horizontal)
          .padding(.bottom)
          .disabled(isLoading)
        }
      }
      .navigationTitle("Add address")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button(action: {
            if isEditing {
              // Cancel editing - reset to original values
              loadAddressFromFirebase()
              isEditing = false
            } else {
              dismiss()
            }
          }) {
            Image(systemName: "chevron.left")
              .foregroundColor(.primary)
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          if isEditing {
            Button("Cancel") {
              loadAddressFromFirebase()
              isEditing = false
            }
          } else {
            Button("Done") {
              dismiss()
            }
          }
        }
      }
      .onAppear {
        loadAddressFromFirebase()
      }
      .onChange(of: locationManager.userLocation) { oldValue, newValue in
        if let location = newValue {
          reverseGeocodeLocation(location)
        }
      }
      .onChange(of: locationManager.authorizationStatus) { oldValue, newValue in
        if newValue == .denied || newValue == .restricted {
          errorMessage = "Location access denied. Please enable location access in Settings."
        }
      }
    }
  }
  
  // Load address from Firebase
  private func loadAddressFromFirebase() {
    guard let userId = Auth.auth().currentUser?.uid else {
      // If no user, parse from currentAddress string
      loadAddressFromString()
      return
    }
    
    isLoading = true
    FirebaseManager.shared.getShippingAddress(userId: userId) { addressData, error in
      DispatchQueue.main.async {
        isLoading = false
        
        if let data = addressData {
          streetAddress = data["street"] as? String ?? ""
          aptNumber = data["aptNumber"] as? String ?? ""
          zipCodeField = data["zip"] as? String ?? ""
          city = data["city"] as? String ?? ""
          state = data["state"] as? String ?? ""
          // Update map after loading address
          updateMapLocation()
        } else {
          // Fallback to parsing from currentAddress string
          loadAddressFromString()
        }
      }
    }
  }
  
  // Load address from currentAddress string (fallback)
  private func loadAddressFromString() {
    // Parse the current address string to populate fields
    let parts = currentAddress.components(separatedBy: ", ")
    
    if parts.count >= 3 {
      let streetParts = parts[0]
      if streetParts.contains("Apt ") {
        let aptParts = streetParts.components(separatedBy: "Apt ")
        if aptParts.count == 2 {
          streetAddress = aptParts[0].trimmingCharacters(in: .whitespaces)
          aptNumber = aptParts[1].trimmingCharacters(in: .whitespaces)
        } else {
          streetAddress = streetParts
        }
      } else {
        streetAddress = streetParts
      }
      
      if parts.count >= 4 {
        city = parts[parts.count - 3]
        state = parts[parts.count - 2]
        zipCodeField = parts[parts.count - 1]
      } else if parts.count == 3 {
        city = parts[1]
        state = parts[2]
        zipCodeField = zipCode
      }
      // Update map after parsing
      updateMapLocation()
    } else {
      streetAddress = currentAddress
      zipCodeField = zipCode
      // Update map even with minimal address
      updateMapLocation()
    }
  }
  
  // Fetch city and state from ZIP code
  private func fetchCityState(zipCode: String) {
    guard zipCode.count == 5, zipCode.allSatisfy({ $0.isNumber }) else {
      return
    }
    
    isLoadingCityState = true
    errorMessage = nil
    
    VCareAPIManager.shared.getCityState(
      zipCode: zipCode,
      agentId: "Sushil", // You might want to get this from user settings
      source: "API"
    ) { result in
      DispatchQueue.main.async {
        isLoadingCityState = false
        
        switch result {
        case .success(let cityState):
          self.city = cityState.city
          self.state = cityState.state
          self.errorMessage = nil
          // Update map after getting city and state
          self.updateMapLocation()
          
        case .failure(let error):
          self.errorMessage = error.localizedDescription
          self.city = ""
          self.state = ""
        }
      }
    }
  }
  
  // Update map location based on address fields
  private func updateMapLocation() {
    // Build address string for geocoding
    var addressComponents: [String] = []
    
    if !streetAddress.isEmpty {
      addressComponents.append(streetAddress)
    }
    if !aptNumber.isEmpty {
      addressComponents.append(aptNumber)
    }
    if !city.isEmpty {
      addressComponents.append(city)
    }
    if !state.isEmpty {
      addressComponents.append(state)
    }
    if !zipCodeField.isEmpty {
      addressComponents.append(zipCodeField)
    }
    
    // If we don't have enough address info, don't geocode
    guard addressComponents.count >= 2 else {
      return
    }
    
    let addressString = addressComponents.joined(separator: ", ")
    
    // Use CLGeocoder to geocode the address
    let geocoder = CLGeocoder()
    geocoder.geocodeAddressString(addressString) { placemarks, error in
      DispatchQueue.main.async {
        if let error = error {
          print("❌ Geocoding error: \(error.localizedDescription)")
          return
        }
        
        if let placemark = placemarks?.first,
           let location = placemark.location {
          // Update map region to show the location
          withAnimation {
            self.cameraPosition = .region(
              MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
              )
            )
            self.annotationCoordinate = location.coordinate
          }
        }
      }
    }
  }
  
  // Save address
  private func saveAddress() {
    // Validate required fields
    guard !streetAddress.isEmpty, !zipCodeField.isEmpty else {
      errorMessage = "Please fill in all required fields"
      return
    }
    
    guard let userId = Auth.auth().currentUser?.uid else {
      errorMessage = "User not authenticated"
      return
    }
    
    isLoading = true
    errorMessage = nil
    
    // Prepare address data
    let addressData: [String: Any] = [
      "street": streetAddress,
      "aptNumber": aptNumber,
      "zip": zipCodeField,
      "city": city,
      "state": state,
      "updatedAt": FieldValue.serverTimestamp()
    ]
    
    
    // Save to Firebase
    FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: addressData) { success, error in
      DispatchQueue.main.async {
        isLoading = false
        
        if success {
          // Update map with saved address
          updateMapLocation()
          // Don't call onChangeAddress - just dismiss and let parent reload
          isEditing = false
          dismiss()
        } else {
          errorMessage = error?.localizedDescription ?? "Failed to save address"
        }
      }
    }
  }
  
  // Use current location
  private func useCurrentLocation() {
    guard isEditing else {
      // Enable editing mode first
      isEditing = true
      // Wait a moment then request location
      Task {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        await MainActor.run {
          requestLocation()
        }
      }
      return
    }
    
    requestLocation()
  }
  
  // Request location
  private func requestLocation() {
    isLoadingLocation = true
    errorMessage = nil
    
    // Check authorization status
    let status = locationManager.authorizationStatus
    switch status {
    case .notDetermined:
      locationManager.requestLocation()
    case .authorizedWhenInUse, .authorizedAlways:
      locationManager.requestLocation()
    case .denied, .restricted:
      isLoadingLocation = false
      errorMessage = "Location access denied. Please enable location access in Settings."
    @unknown default:
      isLoadingLocation = false
    }
  }
  
  // Reverse geocode location to get address
  private func reverseGeocodeLocation(_ location: CLLocation) {
    let geocoder = CLGeocoder()
    geocoder.reverseGeocodeLocation(location, preferredLocale: nil) { placemarks, error in
      Task { @MainActor in
        self.isLoadingLocation = false
        
        if let error = error {
          self.errorMessage = "Failed to get address from location: \(error.localizedDescription)"
          return
        }
        
        guard let placemark = placemarks?.first else {
          self.errorMessage = "Could not determine address from location"
          return
        }
        
        // Extract address components
        var addressComponents: [String] = []
        
        // Street address
        if let streetNumber = placemark.subThoroughfare,
           let streetName = placemark.thoroughfare {
          self.streetAddress = "\(streetNumber) \(streetName)"
          addressComponents.append(self.streetAddress)
        } else if let streetName = placemark.thoroughfare {
          self.streetAddress = streetName
          addressComponents.append(self.streetAddress)
        }
        
        // City
        if let cityName = placemark.locality {
          self.city = cityName
          addressComponents.append(self.city)
        } else if let cityName = placemark.subAdministrativeArea {
          self.city = cityName
          addressComponents.append(self.city)
        }
        
        // State
        if let stateName = placemark.administrativeArea {
          self.state = stateName
          addressComponents.append(self.state)
        }
        
        // ZIP code
        if let zip = placemark.postalCode {
          self.zipCodeField = zip
          addressComponents.append(self.zipCodeField)
        }
        
        // Update map to show the location
        withAnimation {
          self.cameraPosition = .region(
            MKCoordinateRegion(
              center: location.coordinate,
              span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
          )
          self.annotationCoordinate = location.coordinate
        }
        
        // If we have a ZIP code, fetch city/state from API for consistency
        if !self.zipCodeField.isEmpty && self.zipCodeField.count == 5 {
          self.fetchCityState(zipCode: self.zipCodeField)
        }
      }
    }
  }
  
  // Delete address
  private func deleteAddress() {
    guard let userId = Auth.auth().currentUser?.uid else {
      return
    }
    
    // Clear all fields
    streetAddress = ""
    aptNumber = ""
    zipCodeField = ""
    city = ""
    state = ""
    
    // Optionally delete from Firebase
    // You might want to show a confirmation dialog first
    let addressData: [String: Any] = [
      "street": "",
      "aptNumber": "",
      "zip": "",
      "city": "",
      "state": "",
      "updatedAt": FieldValue.serverTimestamp()
    ]
    
    FirebaseManager.shared.saveShippingAddress(userId: userId, addressData: addressData) { success, error in
      if success {
        onChangeAddress()
      }
    }
  }
}

struct AddressInfoSheet_Previews: PreviewProvider {
  static var previews: some View {
    AddressInfoSheet(
      currentAddress: "123 Main St, Apt 4B, New York, NY 10001",
      zipCode: "10001",
      onChangeAddress: {}
    )
  }
}

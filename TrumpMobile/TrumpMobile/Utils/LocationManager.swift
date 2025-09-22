import CoreLocation
import Foundation
import SwiftUI
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  @Published var userLocation: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
  // Loading indicator for active location fetches
  @Published var isFetchingLocation: Bool = false

  override init() {
    super.init()
    manager.delegate = self
    // Set initial status
    self.authorizationStatus = CLLocationManager.authorizationStatus()
  }

  func requestLocation() {
    let status = manager.authorizationStatus
    switch status {
    case .notDetermined:
      // Begin auth flow; show loader until user responds and we attempt a request
      isFetchingLocation = true
      manager.requestWhenInUseAuthorization()
    // The actual request will be made after authorization changes to an allowed state
    case .authorizedWhenInUse, .authorizedAlways:
      isFetchingLocation = true
      manager.requestLocation()
    case .denied, .restricted:
      // Can't proceed; ensure we don't show a spinner
      isFetchingLocation = false
    @unknown default:
      isFetchingLocation = false
    }
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    userLocation = locations.first
    isFetchingLocation = false
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to get user location: \(error)")
    isFetchingLocation = false
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
    switch authorizationStatus {
    case .authorizedWhenInUse, .authorizedAlways:
      // If we were waiting on auth, proceed to request a location once
      if isFetchingLocation {
        self.manager.requestLocation()
      }
    case .denied, .restricted:
      // Stop any pending loader since we can't fetch location
      isFetchingLocation = false
    case .notDetermined:
      break
    @unknown default:
      break
    }
  }
}

// Helper to open app settings
func openAppSettings() {
  if let url = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(url)
  }
}

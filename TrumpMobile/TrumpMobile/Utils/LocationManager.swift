import CoreLocation
import Foundation
import SwiftUI
import UIKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  @Published var userLocation: CLLocation?
  @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

  override init() {
    super.init()
    manager.delegate = self
    // Set initial status
    self.authorizationStatus = CLLocationManager.authorizationStatus()
  }

  func requestLocation() {
    manager.requestWhenInUseAuthorization()
    manager.requestLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    userLocation = locations.first
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Failed to get user location: \(error)")
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    authorizationStatus = manager.authorizationStatus
  }
}

// Helper to open app settings
func openAppSettings() {
  if let url = URL(string: UIApplication.openSettingsURLString) {
    UIApplication.shared.open(url)
  }
}

//
//  TrumpMobileApp.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Firebase Auth persistence is enabled by default
    // No need to explicitly enable it
    
    return true
  }
}

@main
struct TrumpMobileApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  // Create navigationState as a StateObject
  @StateObject private var navigationState = NavigationState()
  
  init() {
    print("DEBUG: TrumpMobileApp initializing")
  }

  var body: some Scene {
    print("DEBUG: TrumpMobileApp body rendering, navigationState exists: \(navigationState != nil)")
    
    return WindowGroup {
      NavigationView {
        SplashView()
          .onAppear {
            print("DEBUG: SplashView appeared in TrumpMobileApp")
          }
      }
      .environmentObject(navigationState)
      // The app will use system appearance for light/dark mode
      // To force light mode, uncomment the following line:
      // UIView.appearance().overrideUserInterfaceStyle = .light
    }
  }
}

//
//  TrumpMobileApp.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//
import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseAnalytics
import FirebaseInAppMessaging


class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    
    // Enable debug mode for faster FIAM testing
    UserDefaults.standard.set(true, forKey: "FIRAnalyticsDebugEnabled")
    
    // Firebase Auth persistence is enabled by default
    // No need to explicitly enable it
    
    return true
  }
}

@main
struct TrumpMobileApp: App {
  // register app delegate for Firebase setup
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  @StateObject private var navigationState = NavigationState()
  @StateObject private var userRegistrationViewModel = UserRegistrationViewModel()
  @StateObject private var contactInfoDetailViewModel = ContactInfoDetailViewModel()

  var body: some Scene {
    WindowGroup {
      NavigationStack {
        SplashView()
      }
      .environmentObject(navigationState)
      .environmentObject(userRegistrationViewModel)
      .environmentObject(contactInfoDetailViewModel)
      // The app will use system appearance for light/dark mode
      // To force light mode, uncomment the following line:
      // UIView.appearance().overrideUserInterfaceStyle = .light
    }
  }
}

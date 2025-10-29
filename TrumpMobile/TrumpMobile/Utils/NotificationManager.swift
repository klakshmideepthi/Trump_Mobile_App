import FirebaseAnalytics
import FirebaseInstallations
import Foundation
import UserNotifications

class NotificationManager: ObservableObject {
  static let shared = NotificationManager()

  @Published var permissionGranted = false
  @Published var firebaseInstallationID = ""

  private init() {
    checkPermissionStatus()
    getFirebaseInstallationID()
  }

  // MARK: - Local Notifications
  func requestPermission() {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .badge, .sound]
    ) { granted, error in
      DispatchQueue.main.async {
        self.permissionGranted = granted
        print("📱 Local notification permission:", granted, error as Any)
      }
    }
  }

  private func checkPermissionStatus() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.permissionGranted = settings.authorizationStatus == .authorized
      }
    }
  }

  func scheduleLocalNotification(
    title: String,
    body: String,
    in seconds: TimeInterval = 5,
    identifier: String? = nil
  ) {
    guard permissionGranted else {
      requestPermission()
      return
    }

    let content = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = .default
    content.badge = 1

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
    let request = UNNotificationRequest(
      identifier: identifier ?? UUID().uuidString,
      content: content,
      trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
      if let error = error {
        print("❌ Failed to schedule notification:", error)
      } else {
        print("✅ Scheduled notification: \(title)")
      }
    }
  }

  // MARK: - Firebase In-App Messaging Events
  func logOrderStarted() {
    Analytics.logEvent(
      "order_started",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: order_started")
  }

  func logStepCompleted(step: Int) {
    Analytics.logEvent(
      "step_completed",
      parameters: [
        "step_number": step,
        "timestamp": Int(Date().timeIntervalSince1970),
      ])
    print("📊 Logged: step_completed (step \(step))")
  }

  func logOrderCompleted() {
    Analytics.logEvent(
      "order_completed",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: order_completed")

    // Schedule a celebration notification
    scheduleLocalNotification(
      title: "🎉 Order Complete!",
      body: "Your Telgoo5 Mobile order has been successfully submitted.",
      in: 2,
      identifier: "order_complete"
    )
  }

  func logUserEngagement() {
    Analytics.logEvent(
      "user_engaged",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: user_engaged")
  }

  func logAppOpened() {
    Analytics.logEvent(
      "app_opened",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: app_opened")
  }

  // MARK: - NEW eSIM Events
  func logESIMProvisioned() {
    Analytics.logEvent(
      "esim_provisioned",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970),
        "sim_type": "eSIM",
      ])
    print("📊 Logged: esim_provisioned")
  }

  func logESIMSetupStarted() {
    Analytics.logEvent(
      "esim_setup_started",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: esim_setup_started")
  }

  func logESIMSetupCompleted() {
    Analytics.logEvent(
      "esim_setup_completed",
      parameters: [
        "timestamp": Int(Date().timeIntervalSince1970)
      ])
    print("📊 Logged: esim_setup_completed")

    // Schedule eSIM activation success notification
    scheduleLocalNotification(
      title: "✅ eSIM Activated!",
      body: "Your Telgoo5 Mobile eSIM is now active and ready to use.",
      in: 2,
      identifier: "esim_activated"
    )
  }

  // MARK: - Firebase Installation ID for testing
  private func getFirebaseInstallationID() {
    Installations.installations().installationID { [weak self] id, error in
      DispatchQueue.main.async {
        self?.firebaseInstallationID = id ?? "Unknown"
        print("🔥 Firebase Installation ID: \(self?.firebaseInstallationID ?? "nil")")
      }
    }
  }

  // MARK: - Predefined notification templates
  func sendWelcomeNotification() {
    scheduleLocalNotification(
      title: "Welcome to Telgoo5 Mobile! 🇺🇸",
      body: "Get started with your new mobile service today.",
      in: 3,
      identifier: "welcome"
    )
  }

  func sendOrderReminderNotification() {
    scheduleLocalNotification(
      title: "Complete Your Order",
      body: "You have an incomplete Telgoo5 Mobile order. Tap to continue.",
      in: 10,
      identifier: "order_reminder"
    )
  }

  func sendSimShippingNotification() {
    scheduleLocalNotification(
      title: "📦 SIM Card Shipped!",
      body: "Your Telgoo5 Mobile SIM card is on its way. Track your package in the app.",
      in: 5,
      identifier: "sim_shipped"
    )
  }

  // NEW: eSIM ready notification
  func sendESIMReadyNotification() {
    scheduleLocalNotification(
      title: "📱 Your eSIM is Ready!",
      body: "Tap to start setting up your Telgoo5 Mobile eSIM.",
      in: 3,
      identifier: "esim_ready"
    )
  }

  // MARK: - Testing helper
  func triggerAllFIAMEvents() {
    logAppOpened()

    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      self.logOrderStarted()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      self.logStepCompleted(step: 3)
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
      self.logUserEngagement()
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
      self.logESIMProvisioned()
    }
  }
}

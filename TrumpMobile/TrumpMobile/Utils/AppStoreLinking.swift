import UIKit

/// Lightweight helpers to deep link into apps, with App Store and web fallbacks.
enum AppStoreLinking {
  // YouTube App Store ID
  private static let youtubeAppId = "544007664"

  // Scheme to open the YouTube app (home screen). You can extend to a specific video/channel if needed.
  private static let youtubeScheme = URL(string: "youtube://")!

  // Direct App Store deep link (itms-apps opens the App Store app without Safari)
  // Use a region to avoid redirect issues (adjust if your primary market differs)
  private static let youtubeStoreURL = URL(string: "itms-apps://apps.apple.com/us/app/id544007664")!

  // Web fallback (opens in Safari if the App Store deep link isn't available e.g. Simulator)
  private static let youtubeStoreWebURL = URL(string: "https://apps.apple.com/us/app/id544007664")!

  /// Opens the YouTube app if installed, otherwise jumps to its App Store page.
  /// Falls back to the web App Store page when running in environments where the App Store app isn't available (e.g. Simulator).
  static func openYouTube() {
    let app = UIApplication.shared

    // 1) Try to open the YouTube app directly
    if app.canOpenURL(youtubeScheme) {
      app.open(youtubeScheme, options: [:], completionHandler: nil)
      return
    }

    // 2) Try to open the App Store app, fall back to the web page if needed (e.g., on Simulator)
    DispatchQueue.main.async {
      app.open(youtubeStoreURL, options: [:]) { success in
        if !success {
          app.open(youtubeStoreWebURL, options: [:], completionHandler: nil)
        }
      }
    }
  }
}

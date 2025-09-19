//
//  ContentView.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//

import FirebaseAnalytics
import FirebaseAuth
import SwiftUI

struct ContentView: View {
  @StateObject private var viewModel = UserRegistrationViewModel()
  @StateObject private var notificationManager = NotificationManager.shared
  @State private var isSignedIn: Bool = false
  @State private var isNewAccount = true
  @State private var orderStep: Int = 0  // 0 = Start Order View
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject private var navigationState: NavigationState

  // Add auth state listener
  @State private var authStateListener: AuthStateDidChangeListenerHandle?

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()

      VStack(spacing: 0) {
        // Show appropriate start view based on orderStep and account type
        if orderStep == 0 {
          if isNewAccount {
            StartOrderView(
              onStart: { orderId in
                // Only proceed if we have a valid order ID
                guard let orderId = orderId, !orderId.isEmpty else {
                  print("❌ ContentView: Cannot proceed without valid order ID from StartOrderView")
                  return
                }

                print("✅ ContentView: Proceeding with order ID from StartOrderView: \(orderId)")
                viewModel.resetOrderSpecificFields()
                viewModel.orderId = orderId
                orderStep = 1
              },
              onLogout: {
                handleLogout()
              }
            )
          } else {
            ExistingUserStartOrderView(
              previousOrders: viewModel.previousOrders,
              onStart: { orderId in
                // Only proceed if we have a valid order ID
                guard let orderId = orderId, !orderId.isEmpty else {
                  print("❌ ContentView: Cannot proceed without valid order ID")
                  return
                }

                print("✅ ContentView: Proceeding with order ID: \(orderId)")
                viewModel.resetOrderSpecificFields()
                viewModel.orderId = orderId
                orderStep = 1
              },
              onLogout: {
                handleLogout()
              }
            )
          }
        } else {
          // Show order flow steps
          switch orderStep {
          case 1:
            ContactInfoView(
              viewModel: viewModel,
              onNext: { orderStep = 2 },
              onCancel: {
                orderStep = 0
              }
            )
          case 2:
            DeviceCompatibilityView(
              viewModel: viewModel,
              onNext: {
                viewModel.saveDeviceInfo { success in
                  if success {
                    orderStep = 3
                  }
                }
              },
              onBack: { orderStep = 1 },
              onCancel: {
                orderStep = 0
              }
            )
          case 3:
            SimSelectionView(
              viewModel: viewModel,
              onNext: {
                viewModel.saveSimSelection { success in
                  if success {
                    orderStep = 4
                  }
                }
              },
              onBack: { orderStep = 2 },
              onCancel: {
                orderStep = 0
              }
            )
          case 4:
            NumberSelectionView(
              viewModel: viewModel,
              onNext: {
                viewModel.saveNumberSelection { success in
                  if success {
                    orderStep = 5
                  }
                }
              },
              onBack: { orderStep = 3 },
              onCancel: {
                orderStep = 0
              }
            )
          case 5:
            BillingInfoView(
              viewModel: viewModel,
              onNext: {
                viewModel.saveBillingInfo { success in
                  if success {
                    orderStep = 6
                  }
                }
              },
              onBack: { orderStep = 4 },
              onCancel: {
                orderStep = 0
              }
            )
          case 6:
            NumberPortingView(
              viewModel: viewModel,
              onNext: {
                // Reset order-specific fields and go to home
                viewModel.resetOrderSpecificFields()
                orderStep = 0
                // Also update navigation state
                navigationState.navigateTo(.startNewOrder)
              },
              onBack: { orderStep = 5 },
              onCancel: {
                // Reset order-specific fields and go to home
                viewModel.resetOrderSpecificFields()
                orderStep = 0
                // Also update navigation state
                navigationState.navigateTo(.startNewOrder)
              }
            )
          default:
            // Fallback to step 0
            EmptyView()
          }
        }
      }
      .padding()
      .onAppear {
        // Set up auth state listener when view appears
        authStateListener = Auth.auth().addStateDidChangeListener { auth, user in

          // If user is signed in
          if let user = user {

            // Send welcome notification for new users
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
              notificationManager.sendWelcomeNotification()
            }

            // Load user data if necessary
            viewModel.userId = user.uid
            viewModel.loadUserData { _ in }

            // Fetch previous orders and set isNewAccount accordingly
            viewModel.fetchPreviousOrders { orders in
              if let orders = orders, !orders.isEmpty {
                isNewAccount = false
                print("DEBUG: Existing user with orders found")
              } else {
                isNewAccount = true
              }
            }
          }
        }
      }
      .onDisappear {
        // Remove auth state listener when view disappears
        if let handle = authStateListener {
          Auth.auth().removeStateDidChangeListener(handle)
        }
      }
      .onChange(of: navigationState.currentDestination) { _, newDestination in
        print("DEBUG: ContentView detected navigation change to: \(newDestination)")
        print("DEBUG: Previous state - orderStep: \(orderStep)")

        // Intentionally add a small delay to ensure the UI updates properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          print("DEBUG: Processing navigation change after delay")
          switch newDestination {
          case .home, .startNewOrder:
            print("DEBUG: Setting state for StartOrderView navigation")
            orderStep = 0
            print("DEBUG: After setting state - orderStep: \(orderStep)")
          case .orderFlow:
            print("DEBUG: Setting state for OrderFlow navigation")
            orderStep = 1
            print("DEBUG: After setting state - orderStep: \(orderStep)")
          case .orderDetails:
            print("DEBUG: Setting state for OrderDetails navigation")
            // Handle OrderDetails navigation if needed
            break
          default:
            print("DEBUG: Unknown navigation destination: \(newDestination)")
            break
          }
        }
      }
    }
  }

  private func handleLogout() {
    print("🔄 ContentView handleLogout called")

    // Remove auth state listener before logout
    if let handle = authStateListener {
      Auth.auth().removeStateDidChangeListener(handle)
      authStateListener = nil
    }

    viewModel.logout { success in
      DispatchQueue.main.async {
        if success {
          print("✅ Logout successful, updating UI state")
        } else {
          print("⚠️ Logout had issues but continuing with UI reset")
        }

        // Reset UI state
        self.isSignedIn = false
        self.isNewAccount = true
        self.orderStep = 0

        // Trigger splash screen display
        self.navigationState.showSplashScreen()
      }
    }
  }
}

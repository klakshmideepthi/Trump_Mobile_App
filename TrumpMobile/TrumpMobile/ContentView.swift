//
//  ContentView.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//

import FirebaseAnalytics
import FirebaseAuth
import FirebaseFirestore
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
                // Attempt to resume at saved step for this order
                if let userId = Auth.auth().currentUser?.uid {
                  Firestore.firestore().collection("users").document(userId)
                    .collection("orders").document(orderId).getDocument { snapshot, _ in
                      let step = (snapshot?.data()?["currentStep"] as? Int) ?? 1
                      orderStep = max(1, min(6, step))
                      // Hydrate view model with saved order data once
                      viewModel.prefillFromOrder(orderId: orderId, completion: nil)
                    }
                } else {
                  orderStep = 1
                  // Also hydrate when possible; prefill will no-op if unauthenticated
                  viewModel.prefillFromOrder(orderId: orderId, completion: nil)
                }
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
                // Attempt to resume at saved step for this order
                if let userId = Auth.auth().currentUser?.uid {
                  Firestore.firestore().collection("users").document(userId)
                    .collection("orders").document(orderId).getDocument { snapshot, _ in
                      let step = (snapshot?.data()?["currentStep"] as? Int) ?? 1
                      orderStep = max(1, min(6, step))
                      // Hydrate view model with saved order data once
                      viewModel.prefillFromOrder(orderId: orderId, completion: nil)
                    }
                } else {
                  orderStep = 1
                  // Also hydrate when possible; prefill will no-op if unauthenticated
                  viewModel.prefillFromOrder(orderId: orderId, completion: nil)
                }
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
                    if let userId = viewModel.userId, let orderId = viewModel.orderId {
                      FirebaseOrderManager.shared.saveStepProgress(
                        userId: userId, orderId: orderId, step: 2)
                    }
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
                    if let userId = viewModel.userId, let orderId = viewModel.orderId {
                      FirebaseOrderManager.shared.saveStepProgress(
                        userId: userId, orderId: orderId, step: 3)
                    }
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
                    if let userId = viewModel.userId, let orderId = viewModel.orderId {
                      FirebaseOrderManager.shared.saveStepProgress(
                        userId: userId, orderId: orderId, step: 4)
                    }
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
                    if let userId = viewModel.userId, let orderId = viewModel.orderId {
                      FirebaseOrderManager.shared.saveStepProgress(
                        userId: userId, orderId: orderId, step: 5)
                    }
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
                // Mark order as completed, then reset and go to home
                viewModel.completeOrder { _ in
                  if let userId = viewModel.userId, let orderId = viewModel.orderId {
                    FirebaseOrderManager.shared.markOrderCompleted(
                      userId: userId, orderId: orderId, completion: nil)
                  }
                  viewModel.resetOrderSpecificFields()
                  orderStep = 0
                  navigationState.navigateTo(.startNewOrder)
                }
              },
              onBack: { orderStep = 5 },
              onCancel: {
                viewModel.resetOrderSpecificFields()
                orderStep = 0
                navigationState.navigateTo(.startNewOrder)
              }
            )
          default:
            // Fallback to step 0
            EmptyView()
          }
        }
      }
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

            // Attempt to resume latest incomplete order for this user
            FirebaseOrderManager.shared.fetchLatestIncompleteOrder(for: user.uid) { result in
              if case .success(let info) = result {
                // Set order and jump to the saved step
                viewModel.orderId = info.orderId
                orderStep = max(1, min(6, info.currentStep))
                // Hydrate from the saved order so earlier steps show data
                viewModel.prefillFromOrder(orderId: info.orderId, completion: nil)
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
            if let resumeStep = navigationState.orderStartStep {
              orderStep = max(1, min(6, resumeStep))
              navigationState.clearOrderResume()
              // If we're navigating with a specific order, hydrate model once
              if let resumeOrderId = navigationState.currentOrderId {
                viewModel.orderId = resumeOrderId
                viewModel.prefillFromOrder(orderId: resumeOrderId, completion: nil)
              }
            } else {
              orderStep = 1
            }
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

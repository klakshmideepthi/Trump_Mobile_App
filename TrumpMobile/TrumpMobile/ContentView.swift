//
//  ContentView.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseAnalytics

struct ContentView: View {
  @StateObject private var viewModel = UserRegistrationViewModel()
  @StateObject private var notificationManager = NotificationManager.shared
  @State private var isSignedIn: Bool = false
  @State private var isNewAccount = false
  @State private var orderStep: Int = 0 // 0 = Start Order View
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject private var navigationState: NavigationState
  
  // Add auth state listener
  @State private var authStateListener: AuthStateDidChangeListenerHandle?

  var body: some View {
    ZStack {
      Color.trumpBackground.ignoresSafeArea()
      VStack {
        if !isSignedIn {
          LoginView(
            onSignIn: {
              isSignedIn = true
              isNewAccount = false
              orderStep = 0 // Start with StartOrderView
            },
            onNewAccount: {
              isNewAccount = true
            }
          )
        } else {
          // Show StartOrderView or order steps
          switch orderStep {
          case 0:
            // Show "Start New Order" page first
            StartOrderView(
              onStart: { orderId in
                // Always reset order-specific fields first
                viewModel.resetOrderSpecificFields()
                // Set the new orderId from Firestore or UUID
                if let orderId = orderId {
                  viewModel.orderId = orderId
                }
                orderStep = 1
              },
              onLogout: {
                do {
                  try Auth.auth().signOut()
                  isSignedIn = false
                } catch {
                  print("Error signing out: \(error.localizedDescription)")
                }
              }
            )
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
              StartOrderView(
                onStart: { orderId in
                  if let orderId = orderId {
                    viewModel.orderId = orderId
                  }
                  orderStep = 1
                },
                onLogout: {
                  do {
                    try Auth.auth().signOut()
                    isSignedIn = false
                  } catch {
                    print("Error signing out: \(error.localizedDescription)")
                  }
                }
              )
            }
        }
      }
      .padding()
    }
    .onAppear {
      // Request notification permission when app starts
      notificationManager.requestPermission()
      
      // Log app opened event for FIAM
      notificationManager.logAppOpened()

      // Set up auth state listener when view appears
      authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
        isSignedIn = user != nil
        
        // If user is signed in
        if user != nil {
          isSignedIn = true
          
          // Send welcome notification for new users
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            notificationManager.sendWelcomeNotification()
          }
          
          // Load user data if necessary
          viewModel.userId = user?.uid
          viewModel.loadUserData { _ in }
        } else {
          isSignedIn = false
        }
      }
    }
    .onChange(of: navigationState.currentDestination) { newDestination in
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
    .onDisappear {
      // Remove listener when view disappears
      if let handle = authStateListener {
        Auth.auth().removeStateDidChangeListener(handle)
      }
    }
  }
}

#Preview {
  ContentView()
}

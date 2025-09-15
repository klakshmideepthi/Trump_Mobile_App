//
//  ContentView.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseAnalytics
// Import color theme extension
// import Color_Theme


struct ContentView: View {
  @StateObject private var viewModel = UserRegistrationViewModel()
  @StateObject private var notificationManager = NotificationManager.shared
  @State private var isSignedIn: Bool = false
  @State private var isNewAccount = false
  @State private var registrationStep: Int = 0 // 0 = Start Order View
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject private var navigationState: NavigationState
  
  init() {
    print("DEBUG: ContentView initializing")
  }
  
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
              registrationStep = 0 // Start with StartOrderView
            },
            onNewAccount: {
              isNewAccount = true
            }
          )
        } else if isNewAccount {
          RegistrationFlowView(startStep: .createAccount)
        } else {
          // Show StartOrderView or registration steps
          switch registrationStep {
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
                registrationStep = 1
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
              onNext: { registrationStep = 2 },
              onCancel: {
                  registrationStep = 0
              }
            )
            case 2:
              DeviceCompatibilityView(
                viewModel: viewModel,
                onNext: { 
                    viewModel.saveDeviceInfo { success in
                        if success {
                            registrationStep = 3
                        }
                    }
                },
                onBack: { registrationStep = 1 },
                onCancel: {
                    registrationStep = 0
                }
              )
            case 3:
              SimSelectionView(
                viewModel: viewModel,
                onNext: { 
                    viewModel.saveSimSelection { success in
                        if success {
                            registrationStep = 4
                        }
                    }
                },
                onBack: { registrationStep = 2 },
                onCancel: {
                    registrationStep = 0
                }
              )
            case 4:
              NumberSelectionView(
                viewModel: viewModel,
                onNext: { 
                    viewModel.saveNumberSelection { success in
                        if success {
                            registrationStep = 5
                        }
                    }
                },
                onBack: { registrationStep = 3 },
                onCancel: {
                    registrationStep = 0
                }
              )
            case 5:
              BillingInfoView(
                viewModel: viewModel,
                onNext: { 
                    viewModel.saveBillingInfo { success in
                        if success {
                            registrationStep = 6
                        }
                    }
                },
                onBack: { registrationStep = 4 },
                onCancel: {
                    registrationStep = 0
                }
              )
            case 6:
              NumberPortingView(
                viewModel: viewModel,
                onNext: { 
                    // Reset order-specific fields and go to home
                    viewModel.resetOrderSpecificFields()
                    registrationStep = 0
                    // Also update navigation state
                    navigationState.navigateTo(.startNewOrder)
                },
                onBack: { registrationStep = 5 },
                onCancel: { 
                    // Reset order-specific fields and go to home
                    viewModel.resetOrderSpecificFields()
                    registrationStep = 0
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
                  registrationStep = 1
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
        print("DEBUG: Previous state - registrationStep: \(registrationStep)")
        
        // Intentionally add a small delay to ensure the UI updates properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: Processing navigation change after delay")
            switch newDestination {
            case .home, .startNewOrder:
                print("DEBUG: Setting state for StartOrderView navigation")
                registrationStep = 0
                print("DEBUG: After setting state - registrationStep: \(registrationStep)")
            case .orderFlow:
                print("DEBUG: Setting state for OrderFlow navigation")
                registrationStep = 1
                print("DEBUG: After setting state - registrationStep: \(registrationStep)")
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

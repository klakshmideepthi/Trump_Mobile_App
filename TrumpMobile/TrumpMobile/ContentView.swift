//
//  ContentView.swift
//  TrumpMobile
//
//  Created by Lakshmi Deepthi Kurugundla on 9/9/25.
//


import SwiftUI
import FirebaseAuth
// Import color theme extension
// import Color_Theme


struct ContentView: View {
  @StateObject private var viewModel = UserRegistrationViewModel()
  @State private var isSignedIn: Bool = false
  @State private var showStartOrder = false
  @State private var isNewAccount = false
  @State private var registrationStep: Int = 0 // 0 = Home View or Start Order View
  @State private var showOrderFlow: Bool = false
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
              registrationStep = 1
            },
            onNewAccount: {
              isNewAccount = true
              showStartOrder = false
            }
          )
        } else if showStartOrder {
          if isNewAccount {
            RegistrationFlowView(startStep: .createAccount)
          } else if registrationStep == 0 {
            // Show "Start New Order" page first
            StartOrderView(
              onStart: { orderId in
                // Set the order ID in the view model
                if let orderId = orderId {
                  viewModel.orderId = orderId
                }
                registrationStep = 1
              },
              onLogout: {
                do {
                  try Auth.auth().signOut()
                  isSignedIn = false
                  showStartOrder = false
                } catch {
                  print("Error signing out: \(error.localizedDescription)")
                }
              }
            )
          } else {
            // Existing user registration steps with back support
            switch registrationStep {
            case 1:
              ContactInfoView(
                viewModel: viewModel,
                onNext: { registrationStep = 2 },
                onCancel: {
                    showStartOrder = false
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
                    showStartOrder = false
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
                    showStartOrder = false
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
                    showStartOrder = false
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
                    showStartOrder = false
                    registrationStep = 0
                }
              )
            case 6:
              OrderCompletionView(
                viewModel: viewModel,
                onBack: { registrationStep = 5 },
                onGoToHome: { 
                    // Reset to start a new order
                    registrationStep = 0
                    // Also update navigation state
                    navigationState.navigateTo(.startNewOrder)
                }
              )
            default:
              ContactInfoView(
                viewModel: viewModel,
                onNext: { registrationStep = 2 }
              )
            }
          }
        } else {
            HomeView(
              onStartOrder: {
                showStartOrder = true
                registrationStep = 0 // Reset to start of order flow
              },
              onLogout: {
                do {
                  try Auth.auth().signOut()
                  isSignedIn = false
                  showStartOrder = false
                } catch {
                  print("Error signing out: \(error.localizedDescription)")
                }
              }
            )
        }
      }
      .padding()
    }
    .onAppear {
      print("DEBUG: ContentView appeared with navigationState destination: \(navigationState.currentDestination)")
      print("DEBUG: ContentView current showStartOrder: \(showStartOrder), registrationStep: \(registrationStep)")
    }
    .onChange(of: navigationState.currentDestination) { newDestination in
        print("DEBUG: ContentView detected navigation change to: \(newDestination)")
        print("DEBUG: Previous state - showStartOrder: \(showStartOrder), registrationStep: \(registrationStep)")
        
        // Intentionally add a small delay to ensure the UI updates properly
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: Processing navigation change after delay")
            switch newDestination {
            case .home:
                print("DEBUG: Setting state for HomeView navigation")
                showStartOrder = false
                registrationStep = 0
                print("DEBUG: After setting state - showStartOrder: \(showStartOrder), registrationStep: \(registrationStep)")
            case .startNewOrder:
                print("DEBUG: Setting state for StartOrderView navigation")
                showStartOrder = true
                registrationStep = 0
                print("DEBUG: After setting state - showStartOrder: \(showStartOrder), registrationStep: \(registrationStep)")
            case .orderFlow:
                print("DEBUG: Setting state for OrderFlow navigation")
                showStartOrder = true
                registrationStep = 1
                print("DEBUG: After setting state - showStartOrder: \(showStartOrder), registrationStep: \(registrationStep)")
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
    .onAppear {
      // Set up auth state listener when view appears
      authStateListener = Auth.auth().addStateDidChangeListener { auth, user in
        isSignedIn = user != nil
        
        // If user is signed in
        if user != nil {
          isSignedIn = true
          
          // Load user data if necessary
          viewModel.userId = user?.uid
          viewModel.loadUserData { _ in }
        } else {
          isSignedIn = false
          showStartOrder = false
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

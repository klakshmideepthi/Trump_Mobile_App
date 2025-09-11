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
              onStart: { registrationStep = 1 },
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
                onNext: { registrationStep = 2 }
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
                onBack: { registrationStep = 1 }
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
                onBack: { registrationStep = 2 }
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
                onBack: { registrationStep = 3 }
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
                onBack: { registrationStep = 4 }
              )
            case 6:
              OrderCompletionView(
                viewModel: viewModel,
                onBack: { registrationStep = 5 }
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

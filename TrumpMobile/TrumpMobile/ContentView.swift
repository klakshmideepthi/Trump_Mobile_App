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
  @State private var isSignedIn: Bool = Auth.auth().currentUser != nil
  @State private var showStartOrder = false
  @State private var isNewAccount = false
  @State private var registrationStep: Int = 0
  @Environment(\.colorScheme) var colorScheme

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
          } else {
            // Existing user registration steps with back support
            switch registrationStep {
            case 1:
              ExistingContactInfoView(
                onNext: { registrationStep = 2 },
                onBack: { showStartOrder = false }
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
              ExistingContactInfoView(
                onNext: { registrationStep = 2 },
                onBack: { showStartOrder = false }
              )
            }
          }
        } else {
            LoginView(
              onSignIn: {
                isSignedIn = true
                showStartOrder = true
              },
              onNewAccount: {
                isNewAccount = true
                isSignedIn = true
                showStartOrder = true
              }
            )
        }
      }
      .padding()
    }
  }
}

#Preview {
  ContentView()
}

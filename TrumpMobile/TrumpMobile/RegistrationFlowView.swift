import SwiftUI
import Firebase

enum RegistrationStep: Int, CaseIterable {
    case createAccount, contactInfo, deviceCompatibility, simSelection, numberSelection, billingInfo, orderCompletion
}

struct RegistrationFlowView: View {
    var startStep: RegistrationStep = .createAccount
    @State private var step: RegistrationStep
    @StateObject private var viewModel = UserRegistrationViewModel()
    @State private var showingAlert = false
    @State private var alertMessage = ""

    init(startStep: RegistrationStep = .createAccount) {
        self.startStep = startStep
        _step = State(initialValue: startStep)
    }
    
    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Processing...")
            } else {
                switch step {
                case .createAccount:
                    CreateAccountView(viewModel: viewModel, onAccountCreated: {
                        step = .contactInfo
                    })
                case .contactInfo:
                    ContactInfoView(viewModel: viewModel) {
                        viewModel.saveContactInfo { success in
                            if success {
                                step = .deviceCompatibility
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Error saving contact information"
                                showingAlert = true
                            }
                        }
                    }
                case .deviceCompatibility:
                    DeviceCompatibilityView(viewModel: viewModel, onNext: {
                        viewModel.saveDeviceInfo { success in
                            if success {
                                step = .simSelection
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Error saving device information"
                                showingAlert = true
                            }
                        }
                    }, onBack: {
                        step = .contactInfo
                    })
                case .simSelection:
                    SimSelectionView(viewModel: viewModel, onNext: {
                        viewModel.saveSimSelection { success in
                            if success {
                                step = .numberSelection
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Error saving SIM selection"
                                showingAlert = true
                            }
                        }
                    }, onBack: {
                        step = .deviceCompatibility
                    })
                case .numberSelection:
                    NumberSelectionView(viewModel: viewModel, onNext: {
                        viewModel.saveNumberSelection { success in
                            if success {
                                step = .billingInfo
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Error saving number selection"
                                showingAlert = true
                            }
                        }
                    }, onBack: {
                        step = .simSelection
                    })
                case .billingInfo:
                    BillingInfoView(viewModel: viewModel, onNext: {
                        viewModel.saveBillingInfo { success in
                            if success {
                                step = .orderCompletion
                            } else {
                                alertMessage = viewModel.errorMessage ?? "Error saving billing information"
                                showingAlert = true
                            }
                        }
                    }, onBack: {
                        step = .numberSelection
                    })
                case .orderCompletion:
                    OrderCompletionView(viewModel: viewModel)
                }
            }
        }
        .padding()
        .animation(.easeInOut, value: step)
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
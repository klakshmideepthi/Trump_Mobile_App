import SwiftUI

struct DeviceCompatibilityView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    // Create a local state to track selection before committing to viewModel
    @State private var selectedBrand: String?
    @State private var selectedModel: String?
    
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    
    var body: some View {
        // Use PhoneCatalog for brands and models
        let brands = PhoneBrand.allCases
        let phoneCatalog = PhoneCatalog.shared

        return StepNavigationContainer(
            currentStep: 2,
            totalSteps: 6,
            nextButtonText: "Next Step",
            nextButtonDisabled: (selectedBrand == nil || selectedBrand == "") || (selectedModel == nil || selectedModel == ""),
            nextButtonAction: {
                // Commit selections to the viewModel when proceeding
                if let brand = selectedBrand {
                    viewModel.deviceBrand = brand
                }
                if let model = selectedModel {
                    viewModel.deviceModel = model
                }
                onNext()
            },
            backButtonAction: {
                if let onBack = onBack {
                    onBack()
                }
            },
            cancelAction: onCancel
        ) {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Check device compatibility")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Let's double check that your device works with Trump Mobile")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 32)

                VStack(spacing: 20) {
                    // Brand Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Device Brand")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        Menu {
                            ForEach(brands) { brand in
                                Button(action: {
                                    selectedBrand = brand.rawValue
                                    
                                    // Set default model when brand changes
                                    if let models = phoneCatalog.models(for: brand).first {
                                        selectedModel = models.name
                                    } else {
                                        selectedModel = nil
                                    }
                                }) {
                                    Text(brand.rawValue)
                                    if selectedBrand == brand.rawValue {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedBrand ?? "Select brand")
                                    .foregroundColor(selectedBrand == nil ? .gray : .primary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }

                    // Model Picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Device Model")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        let availableModels = getAvailableModels(for: selectedBrand ?? "")
                        
                        if selectedBrand == nil || availableModels.isEmpty {
                            HStack {
                                Text("Select brand first")
                                    .foregroundColor(.gray)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.gray)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                        } else {
                            Menu {
                                ForEach(availableModels, id: \.name) { model in
                                    Button(action: {
                                        selectedModel = model.name
                                    }) {
                                        Text(model.name)
                                        if selectedModel == model.name {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(selectedModel ?? "Select model")
                                        .foregroundColor(selectedModel == nil ? .gray : .primary)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }
                    }

                    // Can't find device section
                    if selectedBrand != nil && !getAvailableModels(for: selectedBrand ?? "").isEmpty {
                        Text("Can't find your device in the list above?")
                            .font(.footnote)
                            .foregroundColor(.gray)
                    }

                    Button(action: {
                        // Show IMEI help (could be a sheet/alert)
                    }) {
                        Text("Check your IMEI instead")
                            .font(.subheadline)
                            .foregroundColor(Color("AccentColor2"))
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color("AccentColor2"), lineWidth: 1)
                            )
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)
            }
            .onAppear {
                // Initialize selections from viewModel if they exist
                if !viewModel.deviceBrand.isEmpty {
                    selectedBrand = viewModel.deviceBrand
                }
                if !viewModel.deviceModel.isEmpty {
                    selectedModel = viewModel.deviceModel
                }
                
                // Set device as compatible for the demo
                viewModel.deviceIsCompatible = true
            }
        }
    }
    
    // Helper function to get models for selected brand
    private func getAvailableModels(for brandName: String) -> [PhoneModel] {
        guard !brandName.isEmpty,
              let brand = PhoneBrand.allCases.first(where: { $0.rawValue == brandName }) else {
            return []
        }
        return PhoneCatalog.shared.models(for: brand)
    }
}

struct DeviceCompatibilityView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceCompatibilityView(viewModel: UserRegistrationViewModel(), onNext: {})
    }
}
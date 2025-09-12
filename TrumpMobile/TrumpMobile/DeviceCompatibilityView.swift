import SwiftUI

struct DeviceCompatibilityView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    // Create a local state to track selection before committing to viewModel
    @State private var selectedBrand: String?
    @State private var selectedModel: String?
    @State private var showIMEICheck = false
    @State private var imeiNumber: String = ""
    @State private var imeiCompatible: Bool? = nil
    
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var onCancel: (() -> Void)? = nil
    var showNavigation: Bool = true  // New parameter to control navigation display
    
    var body: some View {
        // Use PhoneCatalog for brands and models
        let brands = PhoneBrand.allCases
        let phoneCatalog = PhoneCatalog.shared
        
        let contentView = VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Check device compatibility")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Let's double check that your device works with Trump Mobile")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 20)
            
            VStack(spacing: 16) {
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
                
                // Compatibility Results Section
                if let selectedModel = selectedModel, !selectedModel.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Results for \(selectedModel)")
                            .font(.headline)
                            .fontWeight(.medium)
                            .padding(.top, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                Text("Device is compatible with our network.")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                Text("You can use an eSIM with your device.")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                                Text("You can use a SIM card with your device.")
                                    .font(.body)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Separator Line
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color("AccentColor"), Color("AccentColor2")]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
                    .padding(.vertical, 8)
                
                // Can't find device section
                VStack(spacing: 16) {
                    Text("Can't find your device in the list above?")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        showIMEICheck = true
                    }) {
                        Text("Check your IMEI instead")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color("AccentColor2"), lineWidth: 1)
                            )
                    }

                    // IMEI Compatibility Section
                    if !imeiNumber.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            if let compatible = imeiCompatible {
                                if compatible {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Your device matches our network!")
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    HStack {
                                        Image(systemName: "xmark.octagon.fill")
                                            .foregroundColor(.red)
                                        Text("Sorry, your device is not compatible.")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
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
        
        // Return either wrapped in navigation container or just the content
        if showNavigation {
            return AnyView(
                StepNavigationContainer(
                    currentStep: 2,
                    totalSteps: 6,
                    nextButtonText: "Next Step",
                    nextButtonDisabled: {
                        let brandSelected = (selectedBrand != nil && selectedBrand != "") && (selectedModel != nil && selectedModel != "")
                        let imeiValid = (!imeiNumber.isEmpty && imeiCompatible == true)
                        // Next is disabled only if neither is valid
                        return !(brandSelected || imeiValid)
                    }(),
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
                    contentView
                }
                .sheet(isPresented: $showIMEICheck) {
                    IMEICheckView(isPresented: $showIMEICheck, onSubmitIMEI: { imei in
                        imeiNumber = imei
                        imeiCompatible = imei.count > 4
                    })
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            )
        } else {
            return AnyView(contentView)
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

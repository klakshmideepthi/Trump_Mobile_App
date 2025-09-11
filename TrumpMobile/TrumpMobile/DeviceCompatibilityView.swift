import SwiftUI

struct DeviceCompatibilityView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        // Sample data for brands and models
        let brands = ["Apple", "Samsung", "Google", "OnePlus"]
        let modelsByBrand: [String: [String]] = [
            "Apple": ["iPhone 15", "iPhone 14", "iPhone 13"],
            "Samsung": ["Galaxy S24", "Galaxy S23", "Galaxy Note 20"],
            "Google": ["Pixel 8", "Pixel 7", "Pixel 6"],
            "OnePlus": ["OnePlus 12", "OnePlus 11", "OnePlus 10"]
        ]

        VStack(spacing: 0) {
            // Stepper at the top
            HStack(spacing: 8) {
                ForEach(1...6, id: \ .self) { step in
                    Text("STEP \(step)")
                        .font(.caption)
                        .fontWeight(step == 2 ? .bold : .regular)
                        .foregroundColor(step == 2 ? Color("AccentColor2") : .white)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(
                            LinearGradient(gradient: Gradient(colors: step == 2 ? [Color("AccentColor2"), Color("AccentColor")] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 32)

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
                    Picker(viewModel.deviceBrand.isEmpty ? "Choose device brand" : viewModel.deviceBrand, selection: $viewModel.deviceBrand) {
                        ForEach(brands, id: \ .self) { brand in
                            Text(brand).tag(brand)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .padding(.horizontal, 0)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                    .onChange(of: viewModel.deviceBrand) { newBrand in
                        if let firstModel = modelsByBrand[newBrand]?.first {
                            viewModel.deviceModel = firstModel
                        } else {
                            viewModel.deviceModel = ""
                        }
                    }
                }

                // Model Picker
                VStack(alignment: .leading, spacing: 6) {
                    Text("Device Model")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Picker(viewModel.deviceModel.isEmpty ? "Choose device model" : viewModel.deviceModel, selection: $viewModel.deviceModel) {
                        ForEach(modelsByBrand[viewModel.deviceBrand] ?? [], id: \ .self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    .padding(.horizontal, 0)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                    )
                }

                // Can't find device section
                if (modelsByBrand[viewModel.deviceBrand]?.isEmpty ?? true) {
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

                // IMEI Field (optional, only if user wants)
                if false { // Hide by default, show if needed
                    TextField("IMEI (optional)", text: $viewModel.imei)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.numberPad)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Next Button
            Button(action: {
                onNext()
            }) {
                HStack {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.white)
                    Image(systemName: "arrow.right")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color("AccentColor2"), Color("AccentColor")]), startPoint: .leading, endPoint: .trailing)
                )
                .cornerRadius(12)
            }
            .disabled(viewModel.deviceBrand.isEmpty || viewModel.deviceModel.isEmpty)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            // Set default values if empty
            if viewModel.deviceBrand.isEmpty {
                viewModel.deviceBrand = brands.first ?? ""
            }
            // Always set model to first for selected brand if not present or not in list
            let models = modelsByBrand[viewModel.deviceBrand] ?? []
            if models.isEmpty {
                viewModel.deviceModel = ""
            } else if !models.contains(viewModel.deviceModel) {
                viewModel.deviceModel = models.first ?? ""
            }
            // Set device as compatible for this demo
            viewModel.deviceIsCompatible = true
        }
    }
}

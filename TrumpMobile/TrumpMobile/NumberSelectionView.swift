import SwiftUI

struct NumberSelectionView: View {
    @ObservedObject var viewModel: UserRegistrationViewModel
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                if let onBack = onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .padding(.leading)
                }
                Spacer()
            }
            Text("Step 5: Transfer existing number or choose a new one").font(.title2)
            HStack {
                Button(action: {
                    viewModel.numberType = "Existing"
                }) {
                    Text("Existing")
                        .padding()
                        .background(viewModel.numberType == "Existing" ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    viewModel.numberType = "New"
                }) {
                    Text("New")
                        .padding()
                        .background(viewModel.numberType == "New" ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            if !viewModel.numberType.isEmpty {
                Text("You selected: \(viewModel.numberType)")
                    .font(.subheadline)
            }
            
            if viewModel.numberType == "New" {
                // Display some sample numbers to choose from
                VStack(alignment: .leading) {
                    Text("Select a number:").font(.headline)
                    
                    Button(action: {
                        viewModel.selectedPhoneNumber = "(202) 555-1234"
                    }) {
                        HStack {
                            Text("(202) 555-1234")
                            Spacer()
                            if viewModel.selectedPhoneNumber == "(202) 555-1234" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.selectedPhoneNumber = "(202) 555-5678"
                    }) {
                        HStack {
                            Text("(202) 555-5678")
                            Spacer()
                            if viewModel.selectedPhoneNumber == "(202) 555-5678" {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.top)
            } else if viewModel.numberType == "Existing" {
                TextField("Enter your current phone number", text: $viewModel.selectedPhoneNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.phonePad)
                    .padding(.top)
            }
            
            Button("Next Step") {
                onNext()
            }
            .disabled(viewModel.numberType.isEmpty || 
                     (viewModel.numberType == "New" && viewModel.selectedPhoneNumber.isEmpty) ||
                     (viewModel.numberType == "Existing" && viewModel.selectedPhoneNumber.isEmpty))
        }
    }
}

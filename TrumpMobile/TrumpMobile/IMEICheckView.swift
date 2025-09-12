import SwiftUI

struct IMEICheckView: View {
    @Binding var isPresented: Bool
    @State private var imeiNumber: String = ""
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Text("FIND OUT IF YOUR PHONE IS COMPATIBLE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // IMEI Input
                    TextField("Enter Your IMEI", text: $imeiNumber)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(8)
                        .font(.body)
                    
                    // Submit Button
                    Button(action: {
                        // Handle IMEI submission
                        isPresented = false
                    }) {
                        Text("Submit & Next")
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color("AccentColor2"))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.black)
                
                // Instructions Section
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("HOW TO FIND YOUR DEVICE'S IMEI NUMBER")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.top, 20)
                        
                        // Tab Selection
                        HStack(spacing: 16) {
                            Button(action: { selectedTab = 0 }) {
                                Text("iOS")
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == 0 ? Color("AccentColor2") : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTab == 0 ? .black : .primary)
                                    .cornerRadius(20)
                            }
                            
                            Button(action: { selectedTab = 1 }) {
                                Text("Android")
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(selectedTab == 1 ? Color("AccentColor2") : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTab == 1 ? .black : .primary)
                                    .cornerRadius(20)
                            }
                            
                            Spacer()
                        }
                        
                        // Instructions Text
                        VStack(alignment: .leading, spacing: 12) {
                            Text("1. To find your IMEI, go to Settings, General, About. You'll find your IMEI there. Alternatively, enter *#06# on your device's dialer to bring up the IMEI. If you see two IMEI numbers, enter either one to check device compatibility.")
                                .font(.body)
                                .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Can't find your IMEI?")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Text("You can skip the compatibility check, but just a heads-up — we can't promise everything will run smoothly if your device isn't compatible. Your call, but don't say we didn't warn you.")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    isPresented = false
                                }) {
                                    Text("Skip compatibility check")
                                        .foregroundColor(.blue)
                                        .font(.body)
                                }
                                .padding(.top, 4)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(Color("AccentColor2"))
                }
            }
        }
    }
}

struct IMEICheckView_Previews: PreviewProvider {
    static var previews: some View {
        IMEICheckView(isPresented: .constant(true))
    }
}

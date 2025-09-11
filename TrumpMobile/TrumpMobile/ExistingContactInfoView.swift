import SwiftUI

struct ExistingContactInfoView: View {
    var onNext: () -> Void
    var onBack: (() -> Void)? = nil
    var body: some View {
        VStack {
            Text("Your Contact Information & Address")
                .font(.title2)
                .padding()
            // TODO: Show actual contact info and address here
            HStack {
                if let onBack = onBack {
                    Button("Back", action: onBack)
                        .padding()
                }
                Spacer()
                Button("Next", action: onNext)
                    .padding()
            }
        }
    }
}

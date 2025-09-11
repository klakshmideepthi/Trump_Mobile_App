import SwiftUI

struct StartOrderView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Text("Welcome!")
                .font(.largeTitle)
                .bold()
            Text("Get started with Trump™ Mobile in just a few steps.")
                .font(.title2)
            Button(action: onStart) {
                Text("Begin")
                    .font(.headline)
            }
            .buttonStyle(GradientButtonStyle())
        }
        .padding()
    }
}

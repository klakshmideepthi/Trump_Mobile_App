import SwiftUI
import Foundation

struct PlanCardView: View {
    let plan: Plan
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(plan.name)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text(plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Text(String(format: "$%.2f / month", plan.price))
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.black.opacity(0.06))
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

struct PlanCardView_Previews: PreviewProvider {
    static var previews: some View {
        PlanCardView(plan: Plan(id: "plan_1", name: "Sample Plan", price: 19.99, description: "Sample plan description"))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}

import SwiftUI

struct PlanSelectionView: View {
    let plans: [Plan]
    let onSelectPlan: (Plan) -> Void
    @State private var selectedPlan: Plan?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Choose Your Plan")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.trumpText)
                    .padding(.top)
                
                ForEach(plans) { plan in
                    PlanCard(
                        plan: plan,
                        isSelected: selectedPlan?.plan_id == plan.plan_id,
                        onSelect: {
                            selectedPlan = plan
                            onSelectPlan(plan)
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct PlanCard: View {
    let plan: Plan
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.display_name ?? plan.plan_name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.trumpText)
                        
                        if let displayDescription = plan.display_description, !displayDescription.isEmpty {
                            Text(displayDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("$\(plan.total_plan_price)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        Text("/month")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !plan.display_features_description.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(plan.display_features_description, id: \.self) { feature in
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentGold)
                                    .font(.caption)
                                Text(feature)
                                    .font(.caption)
                                    .foregroundColor(.trumpText)
                            }
                        }
                    }
                }
                
                // Plan details
                HStack(spacing: 16) {
                    if plan.talk > 0 || plan.minute_unlimited == "Y" {
                        VStack {
                            Text(formatTalk(plan))
                                .font(.headline)
                                .foregroundColor(.trumpText)
                            Text("Minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if plan.text > 0 || plan.text_unlimited == "Y" {
                        VStack {
                            Text(formatText(plan))
                                .font(.headline)
                                .foregroundColor(.trumpText)
                            Text("Messages")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if plan.data > 0 || plan.data_unlimited == "Y" {
                        VStack {
                            Text(formatData(plan))
                                .font(.headline)
                                .foregroundColor(.trumpText)
                            Text("Data")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Carrier information
                if !plan.carrier.isEmpty {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.accentGold)
                            .font(.caption)
                        Text("Carrier: \(plan.carrier.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                if plan.is_familyplan == "Y" {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.accentGold)
                        Text("Family Plan Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Add subtle click indicator
                HStack(spacing: 4) {
                    Text(isSelected ? "Selected" : "Tap to select")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.accentGold, Color.accentGold2]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 4)
            }
            .padding()
            .background(isSelected ? Color.accentGold.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentGold : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatData(_ plan: Plan) -> String {
        // Check if value is extremely large (truly unlimited)
        if plan.data >= 999999999 {
            return "Unlimited"
        }
        // Show actual formatted value (using decimal base: 1000 MB = 1 GB)
        if plan.data >= 1000 {
            let gigabytes = Double(plan.data) / 1000.0
            return "\(Int(gigabytes.rounded()))GB"
        }
        return "\(plan.data)MB"
    }
    
    private func formatTalk(_ plan: Plan) -> String {
        // Check if value is extremely large (truly unlimited)
        if plan.talk >= 999999999 {
            return "∞"
        }
        // Show actual formatted value
        if plan.talk >= 1000 {
            return "\(plan.talk / 1000)K"
        }
        return "\(plan.talk)"
    }
    
    private func formatText(_ plan: Plan) -> String {
        // Check if value is extremely large (truly unlimited)
        if plan.text >= 999999999 {
            return "∞"
        }
        // Show actual formatted value
        if plan.text >= 1000 {
            return "\(plan.text / 1000)K"
        }
        return "\(plan.text)"
    }
}


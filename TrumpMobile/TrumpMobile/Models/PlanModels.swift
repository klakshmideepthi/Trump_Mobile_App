import Foundation

struct Plan: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let price: Double
    let description: String
}

struct PlansData {
    static let allPlans: [Plan] = [
        Plan(id: "plan_1", name: "Basic Saver", price: 9.99, description: "Perfect for light users. Includes 2GB data, unlimited texts, and 100 minutes."),
        Plan(id: "plan_2", name: "Family Plus", price: 19.99, description: "For families or groups. 10GB shared data and unlimited calls/texts."),
        Plan(id: "plan_3", name: "Unlimited Max", price: 29.99, description: "Unlimited data, talk, and text. Free international long distance to select countries."),
        Plan(id: "plan_4", name: "Student Flex", price: 12.99, description: "Affordable. 5GB data, unlimited texts, and free music streaming."),
        Plan(id: "plan_5", name: "Senior Essentials", price: 7.99, description: "Essential talk and text with easy setup for seniors.")
    ]
}

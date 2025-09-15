import Foundation

struct TrumpOrder: Identifiable, Codable {
    let id: String
    let userId: String
    let planName: String
    let amount: Double
    let orderDate: Date
    let status: OrderStatus
    let billingCompleted: Bool
    let phoneNumber: String?
    let simType: String
    
    enum OrderStatus: String, Codable, CaseIterable {
        case pending = "pending"
        case completed = "completed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .pending:
                return "Pending"
            case .completed:
                return "Completed"
            case .cancelled:
                return "Cancelled"
            }
        }
    }
}
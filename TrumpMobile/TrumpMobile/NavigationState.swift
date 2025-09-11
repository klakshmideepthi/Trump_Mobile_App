import Foundation
import SwiftUI

class NavigationState: ObservableObject {
    enum Destination: CustomStringConvertible {
        case startNewOrder
        case orderFlow
        case orderDetails
        case home
        // Add other destinations as needed
        
        var description: String {
            switch self {
            case .startNewOrder: return "startNewOrder"
            case .orderFlow: return "orderFlow"
            case .orderDetails: return "orderDetails"
            case .home: return "home"
            }
        }
    }
    
    init() {
        print("DEBUG: NavigationState initialized with destination: \(currentDestination)")
    }
    
    @Published var currentDestination: Destination = .startNewOrder {
        didSet {
            print("DEBUG: NavigationState destination changed from \(oldValue) to \(currentDestination)")
        }
    }
    
    func navigateTo(_ destination: Destination) {
        print("DEBUG: NavigationState.navigateTo called with destination: \(destination)")
        print("DEBUG: Current destination before change: \(self.currentDestination)")
        self.currentDestination = destination
        print("DEBUG: Current destination after change: \(self.currentDestination)")
    }
    
    func handleOrderCancellation() {
        print("DEBUG: NavigationState.handleOrderCancellation called")
        // Simply navigate to home screen
        DispatchQueue.main.async {
            print("DEBUG: Inside handleOrderCancellation's DispatchQueue.main.async")
            self.navigateTo(.home)
            print("DEBUG: After navigateTo(.home) call in handleOrderCancellation")
        }
    }
}

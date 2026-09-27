import SwiftUI

extension ExpenseCategory {
    /// System colors adapt automatically to dark mode and Increase Contrast.
    var tint: Color {
        switch self {
        case .food: .orange
        case .groceries: .green
        case .transport: .blue
        case .bills: .yellow
        case .shopping: .pink
        case .entertainment: .purple
        case .health: .red
        case .travel: .teal
        case .education: .indigo
        case .other: .gray
        }
    }
}

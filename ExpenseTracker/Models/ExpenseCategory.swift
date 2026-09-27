import Foundation

/// The fixed set of spending categories.
///
/// Persisted through `Expense.categoryRawValue`, so **never rename a raw value**.
/// Add a new case instead. Colors live in `ExpenseCategory+Style.swift` and the
/// App Intents representation lives in `ExpenseCategory+AppEnum.swift`.
enum ExpenseCategory: String, CaseIterable, Codable, Identifiable, Sendable {
    case food
    case groceries
    case transport
    case bills
    case shopping
    case entertainment
    case health
    case travel
    case education
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .food: "Food"
        case .groceries: "Groceries"
        case .transport: "Transport"
        case .bills: "Bills"
        case .shopping: "Shopping"
        case .entertainment: "Entertainment"
        case .health: "Health"
        case .travel: "Travel"
        case .education: "Education"
        case .other: "Other"
        }
    }

    /// SF Symbol name. Keep in sync with `caseDisplayRepresentations` in `ExpenseCategory+AppEnum.swift`.
    var symbolName: String {
        switch self {
        case .food: "fork.knife"
        case .groceries: "cart.fill"
        case .transport: "car.fill"
        case .bills: "bolt.fill"
        case .shopping: "bag.fill"
        case .entertainment: "gamecontroller.fill"
        case .health: "cross.case.fill"
        case .travel: "airplane"
        case .education: "book.fill"
        case .other: "square.grid.2x2.fill"
        }
    }
}

import Foundation

/// Whether money left the account or arrived in it.
///
/// Persisted through `Expense.kindRawValue`, so **never rename a raw value**.
enum TransactionKind: String, CaseIterable, Codable, Identifiable, Sendable {
    case expense
    case income

    var id: String { rawValue }

    var title: String {
        switch self {
        case .expense: "Expense"
        case .income: "Income"
        }
    }
}

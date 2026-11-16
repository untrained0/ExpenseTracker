import Foundation
import SwiftData

extension Notification.Name {
    /// Posted on the main actor after any expense is inserted, updated, or deleted,
    /// and when the review queue (`PendingTransactionStore`) changes.
    static let expenseStoreDidChange = Notification.Name("ExpenseStoreDidChange")
}

enum ExpenseRepositoryError: LocalizedError {
    case invalidAmount

    var errorDescription: String? {
        switch self {
        case .invalidAmount: "The amount must be greater than zero."
        }
    }
}

/// The only type that talks to `ModelContext` (docs/RULES.md §1.4).
/// Every write posts `.expenseStoreDidChange` so any visible screen can refresh.
@MainActor
final class ExpenseRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: Reads

    /// Expenses whose date falls in `[interval.start, interval.end)`, newest first.
    func expenses(in interval: DateInterval) throws -> [Expense] {
        let start = interval.start
        let end = interval.end
        let descriptor = FetchDescriptor<Expense>(
            predicate: #Predicate<Expense> { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func recentExpenses(limit: Int) throws -> [Expense] {
        var descriptor = FetchDescriptor<Expense>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    /// Money spent in the interval; income is not counted.
    /// Summed in memory because SwiftData can't aggregate `Decimal` in a fetch.
    func total(in interval: DateInterval) throws -> Decimal {
        try expenses(in: interval)
            .filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: Writes

    @discardableResult
    func add(
        amount: Decimal,
        category: ExpenseCategory,
        date: Date = .now,
        note: String? = nil,
        kind: TransactionKind = .expense
    ) throws -> Expense {
        guard amount > 0 else { throw ExpenseRepositoryError.invalidAmount }

        let expense = Expense(amount: amount, date: date, category: category, note: note?.nilIfBlank, kind: kind)
        context.insert(expense)
        try saveAndNotify()
        return expense
    }

    func delete(_ expense: Expense) throws {
        context.delete(expense)
        try saveAndNotify()
    }

    private func saveAndNotify() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }
}

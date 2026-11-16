import Foundation
import SwiftData

/// A single transaction: money spent, or (when `kind == .income`) money received.
/// The type keeps its original name because renaming a SwiftData entity needs a migration.
///
/// The model is kept CloudKit-compatible (see docs/RULES.md §2) so iCloud sync can be
/// enabled later without a migration: every stored property has a default value,
/// nothing is `@Attribute(.unique)`, and there are no relationships.
@Model
final class Expense {
    #Index<Expense>([\.date])

    /// Stable identifier that is independent of SwiftData's `persistentModelID`.
    var id: UUID = UUID()
    /// `Decimal` rather than `Double` so sums of money never pick up rounding errors.
    var amount: Decimal = 0
    /// When the money was spent. Defaults to now and the user can edit it.
    var date: Date = Date.now
    /// Backing storage for `category`. A plain string keeps `#Predicate`s simple.
    var categoryRawValue: String = ExpenseCategory.other.rawValue
    var note: String?
    var createdAt: Date = Date.now
    /// Backing storage for `kind`. Rows saved before income existed read as "expense".
    var kindRawValue: String = TransactionKind.expense.rawValue

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = .now,
        category: ExpenseCategory,
        note: String? = nil,
        kind: TransactionKind = .expense
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.categoryRawValue = category.rawValue
        self.note = note
        self.createdAt = .now
        self.kindRawValue = kind.rawValue
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRawValue) ?? .expense }
        set { kindRawValue = newValue.rawValue }
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// The note if there is one, otherwise the category name ("Income" for money received).
    var displayTitle: String {
        if let note, !note.isEmpty { return note }
        return kind == .income ? TransactionKind.income.title : category.title
    }

    /// A plain-value copy for `SpendingAnalytics`.
    var record: TransactionRecord {
        TransactionRecord(amount: amount, date: date, category: category, kind: kind)
    }
}

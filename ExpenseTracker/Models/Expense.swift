import Foundation
import SwiftData

/// A single spending record.
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

    init(
        id: UUID = UUID(),
        amount: Decimal,
        date: Date = .now,
        category: ExpenseCategory,
        note: String? = nil
    ) {
        self.id = id
        self.amount = amount
        self.date = date
        self.categoryRawValue = category.rawValue
        self.note = note
        self.createdAt = .now
    }

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRawValue) ?? .other }
        set { categoryRawValue = newValue.rawValue }
    }

    /// The note if there is one, otherwise the category name.
    var displayTitle: String {
        if let note, !note.isEmpty { return note }
        return category.title
    }
}

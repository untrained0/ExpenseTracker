#if DEBUG
import Foundation
import SwiftData

/// An in-memory store filled with realistic sample data for `#Preview`s.
@MainActor
enum PreviewData {
    static let container: ModelContainer = {
        let container = PersistenceController.makeContainer(inMemory: true)
        let context = container.mainContext
        let now = Date.now
        let hour: TimeInterval = 3_600

        let samples: [(Decimal, ExpenseCategory, String?, TimeInterval)] = [
            (850, .food, "Lunch with team", 2 * hour),
            (400, .transport, nil, 5 * hour),
            (2_300, .groceries, "Weekly groceries", 26 * hour),
            (1_499, .bills, "Mobile + broadband", 30 * hour),
            (650, .entertainment, "Movie night", 50 * hour),
            (220, .food, "Coffee", 74 * hour),
            (5_400, .travel, "Train tickets", 98 * hour),
        ]
        for (amount, category, note, ago) in samples {
            context.insert(Expense(amount: amount, date: now.addingTimeInterval(-ago), category: category, note: note))
        }
        try? context.save()
        return container
    }()

    static let repository = ExpenseRepository(context: container.mainContext)
}
#endif

import AppIntents

/// Exposes categories to Siri, Shortcuts, and the Action Button. When `LogExpenseIntent`
/// asks "What was it for?", the system shows this list with icons.
///
/// The values below must be **literals**: the App Intents metadata extractor reads them at
/// build time and can't call `title` or `symbolName`. Keep them in sync with
/// `ExpenseCategory.swift` by hand.
extension ExpenseCategory: AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"

    static let caseDisplayRepresentations: [ExpenseCategory: DisplayRepresentation] = [
        .food: DisplayRepresentation(title: "Food", image: .init(systemName: "fork.knife")),
        .groceries: DisplayRepresentation(title: "Groceries", image: .init(systemName: "cart.fill")),
        .transport: DisplayRepresentation(title: "Transport", image: .init(systemName: "car.fill")),
        .bills: DisplayRepresentation(title: "Bills", image: .init(systemName: "bolt.fill")),
        .shopping: DisplayRepresentation(title: "Shopping", image: .init(systemName: "bag.fill")),
        .entertainment: DisplayRepresentation(title: "Entertainment", image: .init(systemName: "gamecontroller.fill")),
        .health: DisplayRepresentation(title: "Health", image: .init(systemName: "cross.case.fill")),
        .travel: DisplayRepresentation(title: "Travel", image: .init(systemName: "airplane")),
        .education: DisplayRepresentation(title: "Education", image: .init(systemName: "book.fill")),
        .other: DisplayRepresentation(title: "Other", image: .init(systemName: "square.grid.2x2.fill")),
    ]
}

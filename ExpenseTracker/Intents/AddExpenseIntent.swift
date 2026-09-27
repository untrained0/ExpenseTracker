import AppIntents

/// **Action Button, option A (recommended): open the app on the keypad.**
///
/// `openAppWhenRun = true` makes iOS launch or foreground the app before calling
/// `perform()`. The intent only sets `AppRouter` state, and `RootView` responds by
/// presenting `AddExpenseView` with the amount already active.
///
/// Setup (no Info.plist keys or entitlements needed):
/// 1. Run the app once so iOS registers `ExpenseTrackerShortcuts`.
/// 2. Settings → Action Button → Shortcut → Choose a Shortcut → Expense Tracker → "Add Expense".
///
/// To always preset a category (say, "Food"), create a custom shortcut in the Shortcuts
/// app with this action, set *Category*, and assign that shortcut to the Action Button.
struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Expense"
    static let description = IntentDescription(
        "Opens Expense Tracker directly on the amount keypad.",
        categoryName: "Expenses"
    )
    // Phase note: on iOS 26+ `supportedModes` is the newer way to express this.
    // `openAppWhenRun` still works and also covers our iOS 18 deployment target.
    static let openAppWhenRun: Bool = true

    @Parameter(title: "Category", description: "Preselects a category on the keypad screen.")
    var category: ExpenseCategory?

    @MainActor
    func perform() async throws -> some IntentResult {
        AppRouter.shared.presentAddExpense(category: category, source: .appIntent)
        return .result()
    }
}

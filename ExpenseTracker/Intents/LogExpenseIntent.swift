import AppIntents
import Foundation

/// **Action Button, option B: log without opening the app.**
///
/// `openAppWhenRun = false`, so the whole flow happens in system UI:
/// 1. "How much did you spend?" → numeric input
/// 2. "What was it for?" → category list with icons (from `caseDisplayRepresentations`)
/// 3. Saves, then shows `ExpenseSnippetView` and speaks or shows the dialog.
///
/// The intent is declared in the app target, so it runs in the app's process (launched in
/// the background if needed) and writes to the same `PersistenceController.shared` store.
///
/// Setup: Settings → Action Button → Shortcut → Expense Tracker → "Quick Log".
/// Siri: "Log food expense in Expense Tracker" (category filled from the phrase).
struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription(
        "Logs an expense without opening the app.",
        categoryName: "Expenses"
    )
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Amount",
        requestValueDialog: IntentDialog("How much did you spend?")
    )
    var amount: Double

    @Parameter(
        title: "Category",
        requestValueDialog: IntentDialog("What was it for?")
    )
    var category: ExpenseCategory

    @Parameter(title: "Note")
    var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) for \(\.$category)") {
            \.$note
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard amount > 0 else {
            throw $amount.needsValueError(IntentDialog("The amount must be greater than zero. How much did you spend?"))
        }

        // App Intents hand us a Double. Convert to Decimal and round to cents/paise
        // before it touches storage (docs/RULES.md §2.3).
        let value = Decimal(amount).rounded(scale: 2)

        let repository = ExpenseRepository(context: PersistenceController.shared.mainContext)
        try repository.add(amount: value, category: category, date: .now, note: note)
        let monthTotal = try repository.total(in: Calendar.current.monthInterval(containing: .now))

        let formatted = value.currencyFormatted()
        let snippetNote = note?.nilIfBlank
        let category = category
        // The iOS 26 SDK only resolves the @ViewBuilder `content:` overload here.
        // `.result(dialog:view:)` fails with "extra argument 'view'" (CI run #1).
        return .result(dialog: IntentDialog("Logged \(formatted) for \(category.title).")) {
            ExpenseSnippetView(
                amount: value,
                category: category,
                note: snippetNote,
                monthTotal: monthTotal
            )
        }
    }
}

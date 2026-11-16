import AppIntents

/// **Focus filter: hold expense prompts while a Focus (e.g. Gaming) is on.**
///
/// Setup: Settings → Focus → Gaming → Focus Filters → Add Filter → Expense Tracker →
/// turn on *Hold prompts until this Focus ends*. If the Gaming Focus is set to turn on
/// for your games, no Shortcuts automation is needed.
///
/// The system calls `perform()` with the configured value when the Focus turns on, and
/// with the default (`false`) when it turns off, which releases the queue.
struct ExpensePromptsFocusFilter: SetFocusFilterIntent {
    static let title: LocalizedStringResource = "Hold Expense Prompts"
    static let description: IntentDescription? = IntentDescription(
        "Queues expense prompts while this Focus is on and shows them when it ends."
    )

    @Parameter(title: "Hold prompts until this Focus ends", default: false)
    var holdPrompts: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: holdPrompts ? "Prompts held until the Focus ends" : "Prompts shown as usual")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TransactionCaptureService.forIntents().setHoldingPrompts(holdPrompts)
        return .result()
    }
}

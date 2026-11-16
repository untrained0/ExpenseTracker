import AppIntents

/// **Holds or releases "add this expense?" prompts, for use in automations.**
///
/// The direct way to keep prompts out of a game:
/// - Shortcuts → Automation → **App** → pick the games → *Is Opened* → this action with
///   *Hold* on.
/// - A second automation, same games → *Is Closed* → this action with *Hold* off.
///
/// Turning the hold off immediately sends one prompt for everything that queued up.
/// Bank messages with a readable amount are still logged silently while the hold is on.
struct SetExpensePromptsIntent: AppIntent {
    static let title: LocalizedStringResource = "Hold Expense Prompts"
    static let description = IntentDescription(
        "Holds expense prompts in a queue (for example while a game is open), or releases the queue.",
        categoryName: "Expenses"
    )
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Hold", default: true)
    var hold: Bool

    static var parameterSummary: some ParameterSummary {
        Summary("Hold expense prompts: \(\.$hold)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        TransactionCaptureService.forIntents().setHoldingPrompts(hold)
        return .result()
    }
}

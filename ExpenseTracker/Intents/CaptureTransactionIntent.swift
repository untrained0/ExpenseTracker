import AppIntents
import Foundation

/// **Automatic capture: logs a debit or credit from a bank message.**
///
/// iOS doesn't let an app read SMS or other apps' notifications. The supported route is a
/// Shortcuts *personal automation* that hands the message text to this intent:
///
/// 1. Shortcuts → Automation → **+** → **Message** → *Message Contains* "debited"
///    → **Run Immediately**, turn off *Notify When Run*.
/// 2. Add the action **Capture Bank Message** and set *Message* to **Shortcut Input**.
/// 3. Repeat for "credited" and "spent" (one automation per word).
///
/// A readable amount is saved straight away. Anything unclear goes to the review queue
/// and the user is prompted (or the prompt is held while a game is running).
///
/// It returns a value instead of a dialog on purpose: a dialog would pop up over whatever
/// the user is doing every time a bank message arrives (docs/RULES.md §4.4).
struct CaptureTransactionIntent: AppIntent {
    static let title: LocalizedStringResource = "Capture Bank Message"
    static let description = IntentDescription(
        "Reads a bank or UPI message and logs the debit or credit. Use it in a Message automation with Shortcut Input.",
        categoryName: "Expenses"
    )
    static let openAppWhenRun: Bool = false

    @Parameter(
        title: "Message",
        description: "The text of the bank message. In an automation, choose Shortcut Input.",
        inputOptions: String.IntentInputOptions(multiline: true)
    )
    var message: String

    static var parameterSummary: some ParameterSummary {
        Summary("Capture transaction from \(\.$message)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let outcome = try TransactionCaptureService.forIntents().capture(message: message)

        let summary: String
        switch outcome {
        case .ignored:
            summary = "Not a transaction"
        case .duplicate:
            summary = "Already captured"
        case let .logged(amount, kind, category, merchant):
            let label = merchant ?? (kind == .income ? TransactionKind.income.title : category.title)
            summary = "Logged \(amount.currencyFormatted()) · \(label)"
        case .queued(let prompted):
            summary = prompted ? "Needs review" : "Held for review"
        }
        return .result(value: summary)
    }
}

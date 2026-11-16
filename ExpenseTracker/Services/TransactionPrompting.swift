import Foundation

/// Whether the app may show prompts as notifications.
enum PromptAuthorization: Equatable, Sendable {
    case notDetermined
    case allowed
    case denied
}

/// Asks the user to review queued bank messages. A protocol so tests can record prompts
/// instead of posting real notifications.
@MainActor
protocol TransactionPrompting: AnyObject {
    func prompt(for pending: [PendingTransaction])
    func authorization() async -> PromptAuthorization
    /// Shows the system permission alert the first time. Has to run while the app is in
    /// the foreground; an intent running in the background can't ask.
    func requestAuthorization() async
}

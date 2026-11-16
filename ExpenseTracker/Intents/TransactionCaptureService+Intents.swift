import Foundation

extension TransactionCaptureService {
    /// The service wired to the app's real store, for intents that run outside the view
    /// hierarchy (same reasoning as `PersistenceController.shared`, docs/RULES.md §1.6).
    static func forIntents() -> TransactionCaptureService {
        TransactionCaptureService(
            repository: ExpenseRepository(context: PersistenceController.shared.mainContext),
            pendingStore: PendingTransactionStore(),
            prompter: TransactionPromptNotifier()
        )
    }
}

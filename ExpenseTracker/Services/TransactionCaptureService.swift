import Foundation

/// What happened to a message handed to `TransactionCaptureService`.
enum CaptureOutcome: Equatable {
    /// Not a completed transaction (OTP, offer, chat message, …).
    case ignored
    /// The same message was already handled a moment ago.
    case duplicate
    case logged(amount: Decimal, kind: TransactionKind, category: ExpenseCategory, merchant: String?)
    /// Needs the user. `prompted` is `false` while prompts are on hold.
    case queued(prompted: Bool)
}

/// Turns an incoming bank message into a saved transaction, or a review-queue entry
/// when it can't be logged safely.
@MainActor
final class TransactionCaptureService {
    private let repository: ExpenseRepository
    private let pendingStore: PendingTransactionStore
    private let prompter: TransactionPrompting
    private let homeCurrencyCode: String
    private let now: () -> Date

    init(
        repository: ExpenseRepository,
        pendingStore: PendingTransactionStore,
        prompter: TransactionPrompting,
        homeCurrencyCode: String = AppCurrency.code,
        now: @escaping () -> Date = { .now }
    ) {
        self.repository = repository
        self.pendingStore = pendingStore
        self.prompter = prompter
        self.homeCurrencyCode = homeCurrencyCode
        self.now = now
    }

    func capture(message: String) throws -> CaptureOutcome {
        // A hold that expired without being released still owes the user its prompts.
        releaseHeldPromptsIfAllowed()

        guard let parsed = TransactionMessageParser.parse(message) else { return .ignored }
        guard !pendingStore.isDuplicate(message: message, now: now()) else { return .duplicate }

        let category: ExpenseCategory = parsed.kind == .expense
            ? MerchantCategorizer.category(merchant: parsed.merchant, message: message)
            : .other
        // An amount in another currency can't be stored as-is: the app has one currency.
        let isHomeCurrency = parsed.currencyCode == nil || parsed.currencyCode == homeCurrencyCode

        if let amount = parsed.amount, isHomeCurrency {
            try repository.add(
                amount: amount,
                category: category,
                date: now(),
                note: parsed.merchant,
                kind: parsed.kind
            )
            return .logged(amount: amount, kind: parsed.kind, category: category, merchant: parsed.merchant)
        }

        let holding = pendingStore.isHoldingPrompts(now: now())
        let pending = PendingTransaction(
            receivedAt: now(),
            message: message.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: isHomeCurrency ? parsed.amount : nil,
            kind: parsed.kind,
            merchant: parsed.merchant,
            category: parsed.kind == .expense ? category : nil,
            isAnnounced: !holding
        )
        pendingStore.enqueue(pending)
        if !holding {
            prompter.prompt(for: [pending])
        }
        return .queued(prompted: !holding)
    }

    /// Turning the hold off immediately prompts for everything that queued up meanwhile.
    func setHoldingPrompts(_ hold: Bool) {
        pendingStore.setHoldingPrompts(hold, now: now())
        releaseHeldPromptsIfAllowed()
    }

    private func releaseHeldPromptsIfAllowed() {
        guard !pendingStore.isHoldingPrompts(now: now()) else { return }
        let waiting = pendingStore.takeUnannounced()
        if !waiting.isEmpty {
            prompter.prompt(for: waiting)
        }
    }
}

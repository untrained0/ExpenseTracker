import Foundation

/// A bank message that looked like a transaction but couldn't be logged automatically
/// (no readable amount, or an amount in a foreign currency). It waits in
/// `PendingTransactionStore` until the user reviews or ignores it.
struct PendingTransaction: Codable, Identifiable, Equatable, Sendable {
    var id: UUID
    var receivedAt: Date
    /// The original message text, shown during review so the user can read the amount.
    var message: String
    /// Kept as text because `JSONDecoder` can lose `Decimal` precision by going through `Double`.
    private var amountText: String?
    var kind: TransactionKind?
    var merchant: String?
    var category: ExpenseCategory?
    /// `false` while the prompt is being held back (for example during a game).
    var isAnnounced: Bool

    init(
        id: UUID = UUID(),
        receivedAt: Date,
        message: String,
        amount: Decimal? = nil,
        kind: TransactionKind? = nil,
        merchant: String? = nil,
        category: ExpenseCategory? = nil,
        isAnnounced: Bool = false
    ) {
        self.id = id
        self.receivedAt = receivedAt
        self.message = message
        self.amountText = amount.map { String(describing: $0) }
        self.kind = kind
        self.merchant = merchant
        self.category = category
        self.isAnnounced = isAnnounced
    }

    var amount: Decimal? {
        amountText.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
    }
}

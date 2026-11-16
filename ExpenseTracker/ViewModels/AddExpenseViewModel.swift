import Foundation
import Observation

@MainActor
@Observable
final class AddExpenseViewModel {
    static let lastCategoryKey = "lastUsedCategory"

    var amountInput: AmountInput
    var category: ExpenseCategory
    var kind: TransactionKind
    var date: Date
    var note: String
    var errorMessage: String?

    let source: AddExpenseRequest.Source
    /// The bank message being reviewed, if this sheet was opened from the review queue.
    let sourceMessage: String?

    @ObservationIgnored private let repository: ExpenseRepository
    @ObservationIgnored private let pendingStore: PendingTransactionStore?
    @ObservationIgnored private let pendingID: UUID?
    @ObservationIgnored private let defaults: UserDefaults

    init(
        repository: ExpenseRepository,
        request: AddExpenseRequest? = nil,
        pendingStore: PendingTransactionStore? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.pendingStore = pendingStore
        self.pendingID = request?.pendingID
        self.defaults = defaults
        self.source = request?.source ?? .inApp
        self.sourceMessage = request?.sourceMessage
        self.amountInput = request?.amount.map(AmountInput.init(decimal:)) ?? AmountInput()
        self.kind = request?.kind ?? .expense
        self.date = request?.date ?? .now
        self.note = request?.note ?? ""

        // Preset from the intent or URL, otherwise the last category used. Repeat purchases
        // (the daily coffee) then need zero taps on the category row.
        let lastUsed = defaults.string(forKey: Self.lastCategoryKey).flatMap(ExpenseCategory.init(rawValue:))
        self.category = request?.category ?? lastUsed ?? .food
    }

    var amount: Decimal { amountInput.decimalValue }
    var amountText: String { amountInput.displayString() }
    var canSave: Bool { amount > 0 }

    var saveButtonTitle: String {
        canSave ? "Save \(amount.currencyFormatted())" : "Enter an amount"
    }

    func press(_ key: KeypadKey) {
        amountInput.apply(key)
    }

    func clearAmount() {
        amountInput.clear()
    }

    /// Returns `true` once the expense is saved. The view then dismisses itself.
    func save() -> Bool {
        guard canSave else { return false }
        do {
            // Income has no spending category, and shouldn't change the remembered one.
            let isExpense = kind == .expense
            try repository.add(
                amount: amount,
                category: isExpense ? category : .other,
                date: date,
                note: note,
                kind: kind
            )
            if isExpense {
                defaults.set(category.rawValue, forKey: Self.lastCategoryKey)
            }
            if let pendingID {
                pendingStore?.remove(id: pendingID)
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

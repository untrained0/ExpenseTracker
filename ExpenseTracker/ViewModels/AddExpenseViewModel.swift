import Foundation
import Observation

@MainActor
@Observable
final class AddExpenseViewModel {
    static let lastCategoryKey = "lastUsedCategory"

    var amountInput: AmountInput
    var category: ExpenseCategory
    var date: Date = .now
    var note: String = ""
    var errorMessage: String?

    let source: AddExpenseRequest.Source

    @ObservationIgnored private let repository: ExpenseRepository
    @ObservationIgnored private let defaults: UserDefaults

    init(
        repository: ExpenseRepository,
        request: AddExpenseRequest? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.repository = repository
        self.defaults = defaults
        self.source = request?.source ?? .inApp
        self.amountInput = request?.amount.map(AmountInput.init(decimal:)) ?? AmountInput()

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
            try repository.add(amount: amount, category: category, date: date, note: note)
            defaults.set(category.rawValue, forKey: Self.lastCategoryKey)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

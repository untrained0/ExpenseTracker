import Foundation
import Observation

/// A request to show the Add Expense sheet, with optional prefilled values.
struct AddExpenseRequest: Identifiable, Equatable {
    enum Source: String {
        case inApp
        case appIntent
        case url
    }

    let id = UUID()
    var category: ExpenseCategory?
    var amount: Decimal?
    var source: Source
}

/// The single source of truth for app-level navigation.
///
/// App Intents (`AddExpenseIntent`) and deep links only mutate this state.
/// `RootView` observes it and presents UI, so an intent never touches views directly.
@MainActor
@Observable
final class AppRouter {
    static let shared = AppRouter()
    static let urlScheme = "expensetracker"

    /// Non-nil while the Add Expense sheet is presented.
    var addExpenseRequest: AddExpenseRequest?

    /// Presents the Add Expense sheet.
    ///
    /// Does nothing if the sheet is already open, so a second Action Button press
    /// never wipes an amount the user is halfway through typing.
    func presentAddExpense(
        category: ExpenseCategory? = nil,
        amount: Decimal? = nil,
        source: AddExpenseRequest.Source
    ) {
        guard addExpenseRequest == nil else { return }
        addExpenseRequest = AddExpenseRequest(category: category, amount: amount, source: source)
    }

    /// Handles `expensetracker://add?category=food&amount=250`.
    /// Returns `false` for URLs this app doesn't understand.
    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme?.lowercased() == Self.urlScheme,
              url.host()?.lowercased() == "add"
        else { return false }

        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? {
            queryItems.first { $0.name == name }?.value
        }

        let category = value("category").flatMap { ExpenseCategory(rawValue: $0.lowercased()) }
        let amount = value("amount")
            .flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) }
            .flatMap { $0 > 0 ? $0 : nil }

        presentAddExpense(category: category, amount: amount, source: .url)
        return true
    }
}

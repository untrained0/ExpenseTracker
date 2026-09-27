import Foundation
import Testing
@testable import ExpenseTracker

@MainActor
struct AppRouterTests {
    @Test func presentsAddExpense() {
        let router = AppRouter()
        router.presentAddExpense(category: .food, source: .appIntent)
        #expect(router.addExpenseRequest?.category == .food)
        #expect(router.addExpenseRequest?.source == .appIntent)
    }

    @Test func secondRequestDoesNotReplaceOpenSheet() {
        let router = AppRouter()
        router.presentAddExpense(category: .food, source: .appIntent)
        let first = router.addExpenseRequest?.id
        router.presentAddExpense(category: .bills, source: .appIntent)
        #expect(router.addExpenseRequest?.id == first)
        #expect(router.addExpenseRequest?.category == .food)
    }

    @Test func parsesDeepLink() {
        let router = AppRouter()
        let handled = router.handle(url: URL(string: "expensetracker://add?category=Transport&amount=250.5")!)
        #expect(handled)
        #expect(router.addExpenseRequest?.category == .transport)
        #expect(router.addExpenseRequest?.amount == Decimal(string: "250.5"))
        #expect(router.addExpenseRequest?.source == .url)
    }

    @Test func ignoresInvalidValuesButStillOpens() {
        let router = AppRouter()
        #expect(router.handle(url: URL(string: "expensetracker://add?category=nope&amount=-3")!))
        #expect(router.addExpenseRequest?.category == nil)
        #expect(router.addExpenseRequest?.amount == nil)
    }

    @Test func rejectsForeignURLs() {
        let router = AppRouter()
        #expect(router.handle(url: URL(string: "https://example.com/add")!) == false)
        #expect(router.handle(url: URL(string: "expensetracker://settings")!) == false)
        #expect(router.addExpenseRequest == nil)
    }
}

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

    @Test func presentsPendingTransactionForReview() {
        let router = AppRouter()
        let pending = PendingTransaction(
            receivedAt: Date(timeIntervalSince1970: 1_800_000_000),
            message: "USD 12.99 spent at NETFLIX.COM",
            amount: Decimal(string: "12.99"),
            kind: .expense,
            merchant: "Netflix.com",
            category: .entertainment
        )
        router.presentPending(pending)

        let request = router.addExpenseRequest
        #expect(request?.pendingID == pending.id)
        #expect(request?.amount == Decimal(string: "12.99"))
        #expect(request?.category == .entertainment)
        #expect(request?.note == "Netflix.com")
        #expect(request?.date == pending.receivedAt)
        #expect(request?.sourceMessage == pending.message)
        #expect(request?.source == .pending)
    }

    @Test func rejectsForeignURLs() {
        let router = AppRouter()
        #expect(router.handle(url: URL(string: "https://example.com/add")!) == false)
        #expect(router.handle(url: URL(string: "expensetracker://settings")!) == false)
        #expect(router.addExpenseRequest == nil)
    }
}

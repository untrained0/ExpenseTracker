import Foundation
import SwiftData
import Testing
@testable import ExpenseTracker

/// Records prompts instead of posting notifications.
@MainActor
private final class PromptRecorder: TransactionPrompting {
    private(set) var prompts: [[PendingTransaction]] = []
    var state: PromptAuthorization = .notDetermined

    func prompt(for pending: [PendingTransaction]) {
        prompts.append(pending)
    }

    func authorization() async -> PromptAuthorization { state }

    func requestAuthorization() async {
        state = .allowed
    }
}

/// Covers the capture pipeline: parser → repository or review queue → prompt.
@MainActor
struct TransactionCaptureTests {
    let container = PersistenceController.makeContainer(inMemory: true)
    let repository: ExpenseRepository
    let pendingStore: PendingTransactionStore
    private let prompter = PromptRecorder()
    private let clock = Clock()

    /// A clock the tests can move forward.
    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_800_000_000)
    }

    init() {
        repository = ExpenseRepository(context: container.mainContext)
        pendingStore = PendingTransactionStore(
            defaults: UserDefaults(suiteName: "TransactionCaptureTests-\(UUID().uuidString)")!
        )
    }

    private func makeService() -> TransactionCaptureService {
        let clock = clock
        return TransactionCaptureService(
            repository: repository,
            pendingStore: pendingStore,
            prompter: prompter,
            homeCurrencyCode: "INR",
            now: { clock.now }
        )
    }

    private let debit = "Rs.250.00 debited from A/c XX1234 on 15-11-26 to VPA swiggy@icici (UPI Ref No 123456789012)"
    private let unclear = "Your A/c XX1234 has been debited. Check the app for details."

    // MARK: Automatic logging

    @Test func debitIsLoggedAsAnExpenseWithoutPrompting() throws {
        let outcome = try makeService().capture(message: debit)

        #expect(outcome == .logged(amount: 250, kind: .expense, category: .food, merchant: "Swiggy"))
        let saved = try #require(try repository.recentExpenses(limit: 5).first)
        #expect(saved.amount == 250)
        #expect(saved.kind == .expense)
        #expect(saved.category == .food)
        #expect(saved.note == "Swiggy")
        #expect(prompter.prompts.isEmpty)
        #expect(pendingStore.all.isEmpty)
    }

    @Test func creditIsLoggedAsIncomeAndKeptOutOfSpending() throws {
        let message = "Rs 45,000.00 credited to your A/c XX1234 on 01-11-26 by NEFT from ACME CORP. Avl Bal Rs 1,02,345.67"
        let outcome = try makeService().capture(message: message)

        #expect(outcome == .logged(amount: 45_000, kind: .income, category: .other, merchant: "Acme Corp"))
        let saved = try #require(try repository.recentExpenses(limit: 5).first)
        #expect(saved.kind == .income)
        #expect(saved.displayTitle == "Acme Corp")

        let month = Calendar.current.monthInterval(containing: clock.now)
        #expect(try repository.total(in: month) == 0)
    }

    @Test func nonTransactionsAreIgnored() throws {
        let outcome = try makeService().capture(message: "123456 is your OTP for txn of Rs 500.00 at Amazon.")
        #expect(outcome == .ignored)
        #expect(try repository.recentExpenses(limit: 5).isEmpty)
        #expect(pendingStore.all.isEmpty)
    }

    @Test func sameMessageTwiceIsLoggedOnce() throws {
        let service = makeService()
        _ = try service.capture(message: debit)
        clock.now += 60
        #expect(try service.capture(message: debit) == .duplicate)
        #expect(try repository.recentExpenses(limit: 5).count == 1)

        // The same text much later is a new transaction.
        clock.now += PendingTransactionStore.duplicateWindow + 1
        #expect(try service.capture(message: debit) != .duplicate)
        #expect(try repository.recentExpenses(limit: 5).count == 2)
    }

    // MARK: Review queue

    @Test func unreadableAmountIsQueuedAndPrompted() throws {
        let outcome = try makeService().capture(message: unclear)

        #expect(outcome == .queued(prompted: true))
        #expect(try repository.recentExpenses(limit: 5).isEmpty)
        #expect(pendingStore.all.count == 1)
        #expect(prompter.prompts.count == 1)
        #expect(prompter.prompts.first?.first?.message == unclear)
    }

    @Test func foreignCurrencyIsQueuedWithoutAnAmount() throws {
        let outcome = try makeService().capture(message: "USD 12.99 spent on HDFC Bank Card x1234 at NETFLIX.COM on 2026-11-15")

        #expect(outcome == .queued(prompted: true))
        let pending = try #require(pendingStore.all.first)
        #expect(pending.amount == nil)
        #expect(pending.kind == .expense)
        #expect(try repository.recentExpenses(limit: 5).isEmpty)
    }

    // MARK: Holding prompts (gaming)

    @Test func heldPromptsWaitAndArriveTogetherOnRelease() throws {
        let service = makeService()
        service.setHoldingPrompts(true)

        #expect(try service.capture(message: unclear) == .queued(prompted: false))
        clock.now += 60
        #expect(try service.capture(message: "Your card XX9 has been debited. Login for details.") == .queued(prompted: false))
        #expect(prompter.prompts.isEmpty)
        #expect(pendingStore.all.count == 2)

        service.setHoldingPrompts(false)
        #expect(prompter.prompts.count == 1)
        #expect(prompter.prompts.first?.count == 2)

        // Releasing again has nothing left to announce.
        service.setHoldingPrompts(false)
        #expect(prompter.prompts.count == 1)
    }

    @Test func readableAmountsAreStillLoggedWhileHolding() throws {
        let service = makeService()
        service.setHoldingPrompts(true)

        #expect(try service.capture(message: debit) == .logged(amount: 250, kind: .expense, category: .food, merchant: "Swiggy"))
        #expect(prompter.prompts.isEmpty)
    }

    @Test func aHoldThatWasNeverReleasedExpires() throws {
        let service = makeService()
        service.setHoldingPrompts(true)
        _ = try service.capture(message: unclear)
        #expect(prompter.prompts.isEmpty)

        clock.now += PendingTransactionStore.maxHoldDuration + 1
        #expect(pendingStore.isHoldingPrompts(now: clock.now) == false)

        // The next message both releases the stale queue and prompts for itself.
        #expect(try service.capture(message: "Your card XX9 has been debited. Login for details.") == .queued(prompted: true))
        #expect(prompter.prompts.count == 2)
    }

    // MARK: Reviewing

    @Test func savingAReviewedMessageRemovesItFromTheQueue() throws {
        _ = try makeService().capture(message: unclear)
        let pending = try #require(pendingStore.all.first)

        let router = AppRouter()
        router.presentPending(pending)
        let viewModel = AddExpenseViewModel(
            repository: repository,
            request: router.addExpenseRequest,
            pendingStore: pendingStore,
            defaults: UserDefaults(suiteName: "TransactionCaptureTests-\(UUID().uuidString)")!
        )
        #expect(viewModel.sourceMessage == unclear)
        #expect(viewModel.canSave == false)

        viewModel.press(.digit(9))
        viewModel.press(.digit(0))
        #expect(viewModel.save())

        #expect(pendingStore.all.isEmpty)
        #expect(try repository.recentExpenses(limit: 5).first?.amount == 90)
    }

    @Test func dashboardListsAndIgnoresQueuedMessages() throws {
        _ = try makeService().capture(message: unclear)
        let viewModel = DashboardViewModel(repository: repository, pendingStore: pendingStore)
        viewModel.load()
        #expect(viewModel.pending.count == 1)

        viewModel.ignorePending(viewModel.pending[0])
        viewModel.load()
        #expect(viewModel.pending.isEmpty)
    }

    @Test func incomeIsListedButNotCountedInTheMonthTotal() throws {
        let now = clock.now
        try repository.add(amount: 300, category: .food, date: now)
        try repository.add(amount: 5_000, category: .other, date: now, kind: .income)

        let viewModel = DashboardViewModel(repository: repository, now: { now })
        viewModel.load()

        #expect(viewModel.monthTotal == 300)
        #expect(viewModel.monthCount == 1)
        #expect(viewModel.categoryTotals.map(\.category) == [.food])
        #expect(viewModel.sections.first?.expenses.count == 2)
        #expect(viewModel.sections.first?.total == 300)
    }

    // MARK: Setup screen

    @Test func setupScreenReportsPermissionAndReleasesAStuckHold() async throws {
        let service = makeService()
        let viewModel = CaptureSetupViewModel(prompter: prompter, pendingStore: pendingStore, captureService: service)

        await viewModel.refresh()
        #expect(viewModel.authorization == .notDetermined)
        await viewModel.allowNotifications()
        #expect(viewModel.authorization == .allowed)

        // The view model reads the real clock, so hold from "now" rather than the test clock.
        pendingStore.setHoldingPrompts(true)
        pendingStore.enqueue(PendingTransaction(receivedAt: .now, message: unclear))
        await viewModel.refresh()
        #expect(viewModel.isHoldingPrompts)
        #expect(viewModel.pendingCount == 1)

        await viewModel.releaseHeldPrompts()
        #expect(viewModel.isHoldingPrompts == false)
        #expect(prompter.prompts.count == 1)
    }
}

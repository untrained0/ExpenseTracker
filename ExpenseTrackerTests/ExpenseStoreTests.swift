import Foundation
import SwiftData
import Testing
@testable import ExpenseTracker

/// Covers `ExpenseRepository` and `DashboardViewModel` against a fresh in-memory store.
@MainActor
struct ExpenseStoreTests {
    let container = PersistenceController.makeContainer(inMemory: true)
    let repository: ExpenseRepository
    let calendar: Calendar
    /// 15 Sep 2026, 12:00 UTC
    let now: Date

    init() {
        repository = ExpenseRepository(context: container.mainContext)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 12))!
    }

    private func date(daysAgo days: Int) -> Date {
        calendar.date(byAdding: .day, value: -days, to: now)!
    }

    // MARK: Repository

    @Test func addRejectsNonPositiveAmounts() {
        #expect(throws: ExpenseRepositoryError.self) {
            try repository.add(amount: 0, category: .food)
        }
    }

    @Test func addTrimsBlankNotesToNil() throws {
        let blank = try repository.add(amount: 10, category: .food, note: "   ")
        let trimmed = try repository.add(amount: 10, category: .food, note: "  Coffee ")
        #expect(blank.note == nil)
        #expect(trimmed.note == "Coffee")
    }

    @Test func monthFetchExcludesOtherMonths() throws {
        try repository.add(amount: 100, category: .food, date: now)
        try repository.add(amount: 999, category: .bills, date: date(daysAgo: 31))

        let september = calendar.monthInterval(containing: now)
        #expect(try repository.expenses(in: september).count == 1)
        #expect(try repository.total(in: september) == 100)
    }

    @Test func deleteRemovesExpense() throws {
        let expense = try repository.add(amount: 50, category: .food, date: now)
        try repository.delete(expense)
        #expect(try repository.recentExpenses(limit: 10).isEmpty)
    }

    // MARK: DashboardViewModel

    @Test func dashboardComputesMonthTotalsAndShares() throws {
        try repository.add(amount: 300, category: .food, date: now)
        try repository.add(amount: Decimal(string: "100.50")!, category: .transport, date: date(daysAgo: 1))
        try repository.add(amount: 999, category: .bills, date: date(daysAgo: 40))

        let viewModel = DashboardViewModel(repository: repository, calendar: calendar, now: { now })
        viewModel.load()

        #expect(viewModel.monthTotal == Decimal(string: "400.50"))
        #expect(viewModel.monthCount == 2)
        #expect(viewModel.categoryTotals.map(\.category) == [.food, .transport])
        let shareSum = viewModel.categoryTotals.reduce(0) { $0 + $1.share }
        #expect(abs(shareSum - 1) < 0.0001)
    }

    @Test func dashboardGroupsRecentExpensesByDay() throws {
        try repository.add(amount: 10, category: .food, date: now)
        try repository.add(amount: 20, category: .food, date: now.addingTimeInterval(-3_600))
        try repository.add(amount: 30, category: .food, date: date(daysAgo: 1))
        try repository.add(amount: 40, category: .food, date: date(daysAgo: 40))

        let viewModel = DashboardViewModel(repository: repository, calendar: calendar, now: { now })
        viewModel.load()

        #expect(viewModel.sections.map(\.title).prefix(2) == ["Today", "Yesterday"])
        #expect(viewModel.sections.count == 3)
        #expect(viewModel.sections[0].total == 30)
        #expect(viewModel.sections[0].expenses.first?.amount == 10) // newest first
    }

    @Test func emptyStoreProducesEmptyDashboard() {
        let viewModel = DashboardViewModel(repository: repository, calendar: calendar, now: { now })
        viewModel.load()
        #expect(viewModel.monthTotal == 0)
        #expect(viewModel.sections.isEmpty)
        #expect(viewModel.categoryTotals.isEmpty)
    }

    // MARK: AddExpenseViewModel

    @Test func addExpenseSavesAndRemembersCategory() throws {
        let defaults = UserDefaults(suiteName: "AddExpenseTests-\(UUID().uuidString)")!
        let viewModel = AddExpenseViewModel(
            repository: repository,
            request: AddExpenseRequest(category: .travel, source: .appIntent),
            defaults: defaults
        )
        #expect(viewModel.category == .travel)
        #expect(viewModel.canSave == false)

        viewModel.press(.digit(4))
        viewModel.press(.digit(2))
        #expect(viewModel.save())

        #expect(try repository.recentExpenses(limit: 1).first?.amount == 42)
        #expect(defaults.string(forKey: AddExpenseViewModel.lastCategoryKey) == "travel")

        let next = AddExpenseViewModel(repository: repository, defaults: defaults)
        #expect(next.category == .travel)
    }
}

import Foundation
import SwiftData
import Testing
@testable import ExpenseTracker

@MainActor
struct InsightsViewModelTests {
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

    private func date(month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 10))!
    }

    private func makeViewModel() -> InsightsViewModel {
        InsightsViewModel(repository: repository, calendar: calendar, now: { now })
    }

    @Test func loadsTheCurrentMonthAndComparesWithThePreviousOne() throws {
        try repository.add(amount: 500, category: .food, date: date(month: 9, day: 3))
        try repository.add(amount: 40_000, category: .other, date: date(month: 9, day: 1), kind: .income)
        try repository.add(amount: 400, category: .bills, date: date(month: 8, day: 20))

        let viewModel = makeViewModel()
        viewModel.load()

        #expect(viewModel.summary.spent == 500)
        #expect(viewModel.summary.income == 40_000)
        #expect(viewModel.changeFromPreviousMonth == 0.25)
        #expect(viewModel.trend.count == InsightsViewModel.trendMonthCount)
        #expect(viewModel.trend.suffix(2).map(\.total) == [400, 500])
    }

    @Test func movesBetweenMonthsButNotIntoTheFuture() throws {
        try repository.add(amount: 400, category: .bills, date: date(month: 8, day: 20))

        let viewModel = makeViewModel()
        viewModel.load()
        #expect(viewModel.canShowNextMonth == false)

        viewModel.showNextMonth()
        #expect(viewModel.month == calendar.monthInterval(containing: now).start)

        viewModel.showPreviousMonth()
        #expect(viewModel.summary.spent == 400)
        #expect(viewModel.changeFromPreviousMonth == nil)
        #expect(viewModel.canShowNextMonth)

        viewModel.showNextMonth()
        #expect(viewModel.summary.spent == 0)
    }
}

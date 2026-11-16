import Foundation
import Testing
@testable import ExpenseTracker

struct SpendingAnalyticsTests {
    let calendar: Calendar
    /// 15 Sep 2026, 12:00 UTC
    let now: Date

    init() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        self.calendar = calendar
        now = calendar.date(from: DateComponents(year: 2026, month: 9, day: 15, hour: 12))!
    }

    private func date(month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 10))!
    }

    private var september: DateInterval { calendar.monthInterval(containing: now) }

    @Test func summarySeparatesSpendingFromIncome() {
        let records = [
            TransactionRecord(amount: 300, date: date(month: 9, day: 2), category: .food),
            TransactionRecord(amount: 1_200, date: date(month: 9, day: 2), category: .bills),
            TransactionRecord(amount: 50_000, date: date(month: 9, day: 1), category: .other, kind: .income),
            TransactionRecord(amount: 999, date: date(month: 8, day: 30), category: .shopping),
        ]
        let summary = SpendingAnalytics.summary(of: records, in: september, calendar: calendar, now: now)

        #expect(summary.spent == 1_500)
        #expect(summary.income == 50_000)
        #expect(summary.net == 48_500)
        #expect(summary.expenseCount == 2)
        #expect(summary.largestExpense?.amount == 1_200)
        #expect(summary.categories.map(\.category) == [.bills, .food])
        #expect(abs(summary.categories[0].share - 0.8) < 0.0001)
    }

    @Test func dailySeriesCoversEveryDayOfTheMonth() {
        let records = [
            TransactionRecord(amount: 100, date: date(month: 9, day: 3), category: .food),
            TransactionRecord(amount: 50, date: date(month: 9, day: 3), category: .transport),
        ]
        let summary = SpendingAnalytics.summary(of: records, in: september, calendar: calendar, now: now)

        #expect(summary.daily.count == 30)
        #expect(summary.daily[2].total == 150)
        #expect(summary.daily[3].total == 0)
    }

    @Test func dailyAverageUsesElapsedDaysForTheCurrentMonth() {
        let records = [TransactionRecord(amount: 3_000, date: date(month: 9, day: 3), category: .food)]

        let current = SpendingAnalytics.summary(of: records, in: september, calendar: calendar, now: now)
        #expect(current.dailyAverage == 200) // 15 days so far

        let later = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        let past = SpendingAnalytics.summary(of: records, in: september, calendar: calendar, now: later)
        #expect(past.dailyAverage == 100) // all 30 days
    }

    @Test func emptyMonth() {
        let summary = SpendingAnalytics.summary(of: [], in: september, calendar: calendar, now: now)
        #expect(summary.isEmpty)
        #expect(summary.categories.isEmpty)
        #expect(summary.dailyAverage == 0)
    }

    @Test func monthlyTotalsAreOldestFirstAndIncludeEmptyMonths() {
        let records = [
            TransactionRecord(amount: 100, date: date(month: 9, day: 5), category: .food),
            TransactionRecord(amount: 700, date: date(month: 7, day: 20), category: .travel),
            TransactionRecord(amount: 9_000, date: date(month: 7, day: 1), category: .other, kind: .income),
        ]
        let totals = SpendingAnalytics.monthlyTotals(of: records, endingWith: now, count: 3, calendar: calendar)

        #expect(totals.map(\.total) == [700, 0, 100])
        #expect(totals.last?.month == september.start)
    }

    @Test func changeNeedsAPreviousValue() {
        #expect(SpendingAnalytics.change(from: 0, to: 500) == nil)
        #expect(SpendingAnalytics.change(from: 400, to: 500) == 0.25)
        #expect(SpendingAnalytics.change(from: 400, to: 300) == -0.25)
    }
}

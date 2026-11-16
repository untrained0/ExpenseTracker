import Foundation

/// A transaction reduced to plain values, so analytics never touch SwiftData.
struct TransactionRecord: Equatable, Sendable {
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var kind: TransactionKind = .expense
}

/// One category's share of a period's spending.
struct CategoryTotal: Identifiable, Equatable, Sendable {
    let category: ExpenseCategory
    let total: Decimal
    /// 0...1 fraction of the period's spending.
    let share: Double

    var id: ExpenseCategory { category }
}

/// Spending on one calendar day.
struct DayTotal: Identifiable, Equatable, Sendable {
    /// Start of the day.
    let date: Date
    let total: Decimal

    var id: Date { date }
}

/// Spending in one calendar month.
struct MonthTotal: Identifiable, Equatable, Sendable {
    /// Start of the month.
    let month: Date
    let total: Decimal

    var id: Date { month }
}

/// Everything the Insights screen shows for one month.
struct MonthSummary: Equatable, Sendable {
    var spent: Decimal = 0
    var income: Decimal = 0
    var expenseCount = 0
    /// Spending divided by the days that have happened so far in the month.
    var dailyAverage: Decimal = 0
    /// One entry per day of the month, including days with no spending.
    var daily: [DayTotal] = []
    var categories: [CategoryTotal] = []
    var largestExpense: TransactionRecord?

    var net: Decimal { income - spent }
    var isEmpty: Bool { spent == 0 && income == 0 }
}

/// Pure aggregation for the dashboard and Insights screens.
enum SpendingAnalytics {
    /// Spending per category, largest first. Income is left out.
    static func categoryTotals(of records: [TransactionRecord]) -> [CategoryTotal] {
        let expenses = records.filter { $0.kind == .expense }
        let spent = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        guard spent > 0 else { return [] }
        let spentValue = spent.doubleValue
        let order = ExpenseCategory.allCases

        return Dictionary(grouping: expenses, by: \.category)
            .map { category, items in
                let total = items.reduce(Decimal(0)) { $0 + $1.amount }
                return CategoryTotal(category: category, total: total, share: total.doubleValue / spentValue)
            }
            .sorted { lhs, rhs in
                if lhs.total != rhs.total { return lhs.total > rhs.total }
                // Equal totals keep the declaration order, so the list doesn't shuffle between loads.
                return (order.firstIndex(of: lhs.category) ?? 0) < (order.firstIndex(of: rhs.category) ?? 0)
            }
    }

    static func summary(
        of records: [TransactionRecord],
        in month: DateInterval,
        calendar: Calendar,
        now: Date
    ) -> MonthSummary {
        let inMonth = records.filter { $0.date >= month.start && $0.date < month.end }
        let expenses = inMonth.filter { $0.kind == .expense }
        let spent = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let income = inMonth.filter { $0.kind == .income }.reduce(Decimal(0)) { $0 + $1.amount }

        let byDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        var daily: [DayTotal] = []
        var day = calendar.startOfDay(for: month.start)
        while day < month.end {
            daily.append(DayTotal(date: day, total: (byDay[day] ?? []).reduce(0) { $0 + $1.amount }))
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        // For the month in progress, average over the days so far, not the whole month.
        let elapsedDays = daily.filter { $0.date <= now }.count
        let dailyAverage = elapsedDays > 0 ? (spent / Decimal(elapsedDays)).rounded(scale: 2) : 0

        return MonthSummary(
            spent: spent,
            income: income,
            expenseCount: expenses.count,
            dailyAverage: dailyAverage,
            daily: daily,
            categories: categoryTotals(of: expenses),
            largestExpense: expenses.max { $0.amount < $1.amount }
        )
    }

    /// Spending for `count` consecutive months ending with the month that contains `month`, oldest first.
    static func monthlyTotals(
        of records: [TransactionRecord],
        endingWith month: Date,
        count: Int,
        calendar: Calendar
    ) -> [MonthTotal] {
        let lastStart = calendar.monthInterval(containing: month).start

        return (0..<count).reversed().compactMap { offset in
            guard let anchor = calendar.date(byAdding: .month, value: -offset, to: lastStart) else { return nil }
            let interval = calendar.monthInterval(containing: anchor)
            let total = records
                .filter { $0.kind == .expense && $0.date >= interval.start && $0.date < interval.end }
                .reduce(Decimal(0)) { $0 + $1.amount }
            return MonthTotal(month: interval.start, total: total)
        }
    }

    /// Fractional change, e.g. `0.25` for 25% more. `nil` when there's nothing to compare against.
    static func change(from previous: Decimal, to current: Decimal) -> Double? {
        guard previous > 0 else { return nil }
        return (current - previous).doubleValue / previous.doubleValue
    }
}

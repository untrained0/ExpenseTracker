import Foundation
import Observation

/// Expenses from one calendar day, for a list section.
struct DaySection: Identifiable {
    /// Start of the day.
    let id: Date
    let title: String
    let expenses: [Expense]
    let total: Decimal
}

/// One category's share of the month's spending.
struct CategoryTotal: Identifiable, Equatable {
    let category: ExpenseCategory
    let total: Decimal
    /// 0...1 fraction of the month total.
    let share: Double

    var id: ExpenseCategory { category }
}

@MainActor
@Observable
final class DashboardViewModel {
    static let recentLimit = 50

    private(set) var monthTotal: Decimal = 0
    private(set) var monthCount = 0
    private(set) var categoryTotals: [CategoryTotal] = []
    private(set) var sections: [DaySection] = []
    var errorMessage: String?

    @ObservationIgnored private let repository: ExpenseRepository
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let now: () -> Date

    /// `calendar` and `now` are injectable so tests don't depend on the real date.
    init(
        repository: ExpenseRepository,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.repository = repository
        self.calendar = calendar
        self.now = now
    }

    var monthTitle: String {
        now().formatted(.dateTime.month(.wide).year())
    }

    func load() {
        do {
            let monthExpenses = try repository.expenses(in: calendar.monthInterval(containing: now()))
            monthTotal = monthExpenses.reduce(0) { $0 + $1.amount }
            monthCount = monthExpenses.count
            categoryTotals = makeCategoryTotals(from: monthExpenses, monthTotal: monthTotal)
            sections = makeSections(from: try repository.recentExpenses(limit: Self.recentLimit))
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The view reloads through `.expenseStoreDidChange` after this.
    func delete(_ expense: Expense) {
        do {
            try repository.delete(expense)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Private

    private func makeCategoryTotals(from expenses: [Expense], monthTotal: Decimal) -> [CategoryTotal] {
        guard monthTotal > 0 else { return [] }
        let totalValue = monthTotal.doubleValue

        return Dictionary(grouping: expenses, by: \.category)
            .map { category, items in
                let total = items.reduce(Decimal(0)) { $0 + $1.amount }
                return CategoryTotal(category: category, total: total, share: total.doubleValue / totalValue)
            }
            .sorted { $0.total > $1.total }
    }

    private func makeSections(from expenses: [Expense]) -> [DaySection] {
        let byDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }

        return byDay.keys.sorted(by: >).map { day in
            let items = (byDay[day] ?? []).sorted { $0.date > $1.date }
            return DaySection(
                id: day,
                title: sectionTitle(for: day),
                expenses: items,
                total: items.reduce(0) { $0 + $1.amount }
            )
        }
    }

    private func sectionTitle(for day: Date) -> String {
        let today = calendar.startOfDay(for: now())
        if day == today { return "Today" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today), day == yesterday {
            return "Yesterday"
        }
        return day.formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }
}

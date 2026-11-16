import Foundation
import Observation

/// Expenses from one calendar day, for a list section.
struct DaySection: Identifiable {
    /// Start of the day.
    let id: Date
    let title: String
    let expenses: [Expense]
    /// Money spent that day. Income rows are listed but not added in.
    let total: Decimal
}

@MainActor
@Observable
final class DashboardViewModel {
    static let recentLimit = 50

    private(set) var monthTotal: Decimal = 0
    private(set) var monthCount = 0
    private(set) var categoryTotals: [CategoryTotal] = []
    private(set) var sections: [DaySection] = []
    /// Bank messages waiting for review, oldest first.
    private(set) var pending: [PendingTransaction] = []
    var errorMessage: String?

    @ObservationIgnored private let repository: ExpenseRepository
    @ObservationIgnored private let pendingStore: PendingTransactionStore?
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private let now: () -> Date

    /// `calendar` and `now` are injectable so tests don't depend on the real date.
    init(
        repository: ExpenseRepository,
        pendingStore: PendingTransactionStore? = nil,
        calendar: Calendar = .current,
        now: @escaping () -> Date = { .now }
    ) {
        self.repository = repository
        self.pendingStore = pendingStore
        self.calendar = calendar
        self.now = now
    }

    var monthTitle: String {
        now().formatted(.dateTime.month(.wide).year())
    }

    func load() {
        do {
            // The month card is about spending, so income is left out of every figure on it.
            let monthExpenses = try repository.expenses(in: calendar.monthInterval(containing: now()))
                .filter { $0.kind == .expense }
            monthTotal = monthExpenses.reduce(0) { $0 + $1.amount }
            monthCount = monthExpenses.count
            categoryTotals = SpendingAnalytics.categoryTotals(of: monthExpenses.map(\.record))
            sections = makeSections(from: try repository.recentExpenses(limit: Self.recentLimit))
        } catch {
            errorMessage = error.localizedDescription
        }
        pending = pendingStore?.all ?? []
    }

    /// Drops a queued bank message without logging it. The view reloads through
    /// `.expenseStoreDidChange`.
    func ignorePending(_ item: PendingTransaction) {
        pendingStore?.remove(id: item.id)
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

    private func makeSections(from expenses: [Expense]) -> [DaySection] {
        let byDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }

        return byDay.keys.sorted(by: >).map { day in
            let items = (byDay[day] ?? []).sorted { $0.date > $1.date }
            return DaySection(
                id: day,
                title: sectionTitle(for: day),
                expenses: items,
                total: items.filter { $0.kind == .expense }.reduce(0) { $0 + $1.amount }
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

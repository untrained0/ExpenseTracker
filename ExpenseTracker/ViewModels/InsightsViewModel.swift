import Foundation
import Observation

@MainActor
@Observable
final class InsightsViewModel {
    /// How many months the trend chart shows, ending with the selected month.
    static let trendMonthCount = 6

    /// Start of the month on screen.
    private(set) var month: Date
    private(set) var summary = MonthSummary()
    private(set) var trend: [MonthTotal] = []
    /// Spending versus the month before, e.g. `0.25` for 25% more. `nil` without a baseline.
    private(set) var changeFromPreviousMonth: Double?
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
        self.month = calendar.monthInterval(containing: now()).start
    }

    var monthTitle: String {
        month.formatted(.dateTime.month(.wide).year())
    }

    var previousMonthName: String {
        guard let previous = calendar.date(byAdding: .month, value: -1, to: month) else { return "" }
        return previous.formatted(.dateTime.month(.wide))
    }

    /// The future has nothing to show.
    var canShowNextMonth: Bool {
        month < calendar.monthInterval(containing: now()).start
    }

    func showPreviousMonth() {
        shiftMonth(by: -1)
    }

    func showNextMonth() {
        guard canShowNextMonth else { return }
        shiftMonth(by: 1)
    }

    func load() {
        do {
            let selected = calendar.monthInterval(containing: month)
            let windowStart = calendar.date(byAdding: .month, value: -(Self.trendMonthCount - 1), to: selected.start)
                ?? selected.start
            // One fetch covers the selected month, the one before it, and the trend.
            let records = try repository
                .expenses(in: DateInterval(start: windowStart, end: selected.end))
                .map(\.record)

            summary = SpendingAnalytics.summary(of: records, in: selected, calendar: calendar, now: now())
            trend = SpendingAnalytics.monthlyTotals(
                of: records,
                endingWith: month,
                count: Self.trendMonthCount,
                calendar: calendar
            )
            let previousSpent = trend.dropLast().last?.total ?? 0
            changeFromPreviousMonth = SpendingAnalytics.change(from: previousSpent, to: summary.spent)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func shiftMonth(by value: Int) {
        guard let shifted = calendar.date(byAdding: .month, value: value, to: month) else { return }
        month = calendar.monthInterval(containing: shifted).start
        load()
    }
}

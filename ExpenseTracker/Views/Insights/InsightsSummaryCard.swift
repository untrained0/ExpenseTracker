import SwiftUI

/// The month's headline numbers: spent, change versus last month, income, net, daily average.
struct InsightsSummaryCard: View {
    let summary: MonthSummary
    /// Fractional change in spending versus the previous month, if there is a baseline.
    let change: Double?
    let previousMonthName: String

    var body: some View {
        InsightsCard(title: "Spent") {
            VStack(alignment: .leading, spacing: 6) {
                Text(summary.spent.currencyFormatted())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())

                if let change {
                    Label(changeText(change), systemImage: change > 0 ? "arrow.up.right" : "arrow.down.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("^[\(summary.expenseCount) expense](inflect: true)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                stat("Income", summary.income.currencyFormatted())
                stat("Net", summary.net.currencyFormatted())
                stat("Daily average", summary.dailyAverage.currencyFormatted())
            }
        }
    }

    private func changeText(_ change: Double) -> String {
        let percent = abs(change).formatted(.percent.precision(.fractionLength(0)))
        return "\(percent) \(change > 0 ? "more" : "less") than \(previousMonthName)"
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    InsightsSummaryCard(
        summary: MonthSummary(spent: 18_450, income: 62_000, expenseCount: 23, dailyAverage: 1_230),
        change: 0.12,
        previousMonthName: "October"
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

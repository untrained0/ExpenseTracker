import Charts
import SwiftUI

/// Spending per month. The month on screen is highlighted and labelled; the rest are
/// context, so they stay gray.
struct MonthTrendChart: View {
    let months: [MonthTotal]
    let selectedMonth: Date

    var body: some View {
        Chart(months) { item in
            let isSelected = item.month == selectedMonth
            BarMark(
                x: .value("Month", item.month, unit: .month),
                y: .value("Spent", item.total.doubleValue),
                width: .ratio(0.6)
            )
            .foregroundStyle(isSelected ? Color.accentColor : Color(.systemGray3))
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 4, topTrailingRadius: 4))
            .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                if isSelected {
                    Text(item.total.currencyFormatted())
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 3)) { value in
                AxisGridLine().foregroundStyle(Color(.separator).opacity(0.5))
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(ChartAmount.compact(amount))
                    }
                }
            }
        }
        .frame(height: 160)
    }
}

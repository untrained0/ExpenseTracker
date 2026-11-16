import Charts
import SwiftUI

/// One column per day of the month. Touch or drag across the chart to read a day's total.
struct DailySpendChart: View {
    let days: [DayTotal]

    @State private var selectedDate: Date?

    private var selectedDay: DayTotal? {
        guard let selectedDate else { return nil }
        return days.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var highestDay: DayTotal? {
        days.max { $0.total < $1.total }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            readout

            Chart(days) { day in
                BarMark(
                    x: .value("Day", day.date, unit: .day),
                    y: .value("Spent", day.total.doubleValue),
                    width: .ratio(0.7)
                )
                .foregroundStyle(Color.accentColor)
                .opacity(selectedDay == nil || selectedDay == day ? 1 : 0.35)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 3, topTrailingRadius: 3))
            }
            .chartXSelection(value: $selectedDate)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.day())
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
            .frame(height: 180)
        }
    }

    /// The selected day, or the month's highest day when nothing is selected. Always one
    /// line tall so the chart doesn't jump while dragging.
    private var readout: some View {
        let day = selectedDay ?? highestDay
        let prefix = selectedDay == nil ? "Highest · " : ""
        return HStack(alignment: .firstTextBaseline) {
            Text(prefix + (day?.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) ?? ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 8)
            Text((day?.total ?? 0).currencyFormatted())
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

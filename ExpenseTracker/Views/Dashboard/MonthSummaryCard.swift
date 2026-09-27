import SwiftUI

struct MonthSummaryCard: View {
    let monthTitle: String
    let total: Decimal
    let count: Int
    let categoryTotals: [CategoryTotal]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(monthTitle.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(total.currencyFormatted())
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())

                Text("^[\(count) transaction](inflect: true) this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !categoryTotals.isEmpty {
                CategoryShareBar(totals: categoryTotals)
                legend
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 28, style: .continuous)
        )
        .accessibilityElement(children: .combine)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            ForEach(categoryTotals.prefix(3)) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(item.category.tint)
                        .frame(width: 8, height: 8)
                    Text(item.category.title)
                        .foregroundStyle(.primary)
                    Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                        .foregroundStyle(.secondary)
                }
                .lineLimit(1)
            }
        }
        .font(.caption)
    }
}

/// A single horizontal bar split proportionally by category share.
private struct CategoryShareBar: View {
    let totals: [CategoryTotal]
    private let spacing: CGFloat = 2

    var body: some View {
        GeometryReader { proxy in
            let available = proxy.size.width - spacing * CGFloat(max(totals.count - 1, 0))
            HStack(spacing: spacing) {
                ForEach(totals) { item in
                    Capsule()
                        .fill(item.category.tint)
                        .frame(width: max(4, available * item.share))
                }
            }
        }
        .frame(height: 10)
        .accessibilityHidden(true)
    }
}

#Preview {
    MonthSummaryCard(
        monthTitle: "September 2026",
        total: 18_450,
        count: 23,
        categoryTotals: [
            CategoryTotal(category: .food, total: 7_700, share: 0.42),
            CategoryTotal(category: .bills, total: 4_600, share: 0.25),
            CategoryTotal(category: .travel, total: 3_700, share: 0.2),
            CategoryTotal(category: .other, total: 2_450, share: 0.13),
        ]
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

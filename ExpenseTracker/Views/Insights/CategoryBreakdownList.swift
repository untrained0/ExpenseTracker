import SwiftUI

/// Categories ranked by spending. Bars share one baseline and are scaled to the largest
/// category, so close values can be compared; the percentage is each one's share of the month.
struct CategoryBreakdownList: View {
    let totals: [CategoryTotal]

    private var largest: Double {
        totals.map(\.total.doubleValue).max() ?? 0
    }

    var body: some View {
        VStack(spacing: 14) {
            ForEach(totals) { item in
                HStack(spacing: 12) {
                    CategoryIcon(category: item.category, size: 36)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(item.category.title)
                                .font(.subheadline.weight(.medium))
                            Spacer(minLength: 8)
                            Text(item.total.currencyFormatted())
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                        }

                        HStack(spacing: 8) {
                            bar(for: item)
                            Text(item.share.formatted(.percent.precision(.fractionLength(0))))
                                .font(.caption)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                                .frame(width: 40, alignment: .trailing)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    private func bar(for item: CategoryTotal) -> some View {
        GeometryReader { proxy in
            let fraction = largest > 0 ? item.total.doubleValue / largest : 0
            ZStack(alignment: .leading) {
                Capsule().fill(.fill.tertiary)
                Capsule()
                    .fill(item.category.tint)
                    .frame(width: max(6, proxy.size.width * fraction))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

#Preview {
    InsightsCard(title: "By category") {
        CategoryBreakdownList(totals: [
            CategoryTotal(category: .food, total: 7_700, share: 0.42),
            CategoryTotal(category: .bills, total: 4_600, share: 0.25),
            CategoryTotal(category: .travel, total: 3_700, share: 0.2),
            CategoryTotal(category: .other, total: 2_450, share: 0.13),
        ])
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

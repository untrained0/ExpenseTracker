import SwiftUI

/// The card Siri, Shortcuts, and the Action Button show after `LogExpenseIntent` saves.
/// It takes plain values rather than a `@Model`, because snippets render outside the
/// app's view hierarchy (docs/RULES.md §4.5).
struct ExpenseSnippetView: View {
    let amount: Decimal
    let category: ExpenseCategory
    let note: String?
    let monthTotal: Decimal

    var body: some View {
        HStack(spacing: 14) {
            CategoryIcon(category: category, size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(amount.currencyFormatted())
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text(note ?? category.title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("This month")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(monthTotal.currencyFormatted())
                    .font(.headline)
                    .monospacedDigit()
            }
        }
        .padding()
    }
}

#Preview {
    ExpenseSnippetView(amount: 250, category: .food, note: "Coffee", monthTotal: 18_700)
}

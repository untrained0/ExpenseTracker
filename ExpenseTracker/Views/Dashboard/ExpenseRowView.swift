import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            CategoryIcon(category: expense.category)

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.displayTitle)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(expense.amount.currencyFormatted())
                .font(.body.weight(.semibold))
                .monospacedDigit()
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

    /// When a note is the title, the category moves into the subtitle so it stays visible.
    private var subtitle: String {
        let time = expense.date.formatted(date: .omitted, time: .shortened)
        let hasNote = expense.note?.isEmpty == false
        return hasNote ? "\(expense.category.title) · \(time)" : time
    }
}

import SwiftUI

/// A bank message waiting in the review queue.
struct PendingTransactionRow: View {
    let pending: PendingTransaction

    var body: some View {
        HStack(spacing: 14) {
            CategoryIcon(symbolName: "envelope.badge.fill", tint: .accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(pending.message)
                    .font(.subheadline)
                    .lineLimit(2)
                Text("Tap to add · \(pending.receivedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            if let amount = pending.amount {
                Text(amount.currencyFormatted())
                    .font(.body.weight(.semibold))
                    .monospacedDigit()
            } else {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the amount keypad to add this transaction")
    }
}

#Preview {
    List {
        PendingTransactionRow(
            pending: PendingTransaction(
                receivedAt: .now,
                message: "Your A/c XX1234 has been debited. Check the app for details."
            )
        )
    }
}

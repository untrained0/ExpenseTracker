import SwiftUI

/// The hero amount: currency symbol, the number being typed, and a blinking caret
/// while the amount has focus.
struct AmountDisplayView: View {
    let text: String
    let currencySymbol: String
    let isPlaceholder: Bool
    let isFocused: Bool
    let tint: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(currencySymbol)
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)

            Text(text)
                .font(.system(size: 80, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(isPlaceholder ? AnyShapeStyle(.tertiary) : AnyShapeStyle(.primary))
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.2), value: text)

            if isFocused {
                Caret(tint: tint)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 8 }
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Amount")
        .accessibilityValue("\(currencySymbol)\(text)")
    }
}

private struct Caret: View {
    let tint: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(tint)
            .frame(width: 4, height: 60)
            .phaseAnimator([true, false]) { content, visible in
                content.opacity(visible ? 1 : 0)
            } animation: { _ in
                .easeInOut(duration: 0.5)
            }
    }
}

#Preview {
    VStack(spacing: 40) {
        AmountDisplayView(text: "0", currencySymbol: "₹", isPlaceholder: true, isFocused: true, tint: .orange)
        AmountDisplayView(text: "12,34,567.8", currencySymbol: "₹", isPlaceholder: false, isFocused: true, tint: .blue)
    }
}

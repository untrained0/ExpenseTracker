import SwiftUI

/// A large, calculator-style keypad. Keys flex from 56 to 72 pt tall, so the grid
/// fills the iPhone 17 Pro Max comfortably and still fits on an iPhone SE.
struct KeypadView: View {
    var onKey: (KeypadKey) -> Void
    /// Long-press on backspace.
    var onClear: () -> Void = {}

    private let rows: [[KeypadKey]] = [
        [.digit(1), .digit(2), .digit(3)],
        [.digit(4), .digit(5), .digit(6)],
        [.digit(7), .digit(8), .digit(9)],
        [.decimalSeparator, .digit(0), .backspace],
    ]

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                GridRow {
                    ForEach(rows[rowIndex], id: \.self) { key in
                        keyButton(key)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func keyButton(_ key: KeypadKey) -> some View {
        let button = Button {
            onKey(key)
        } label: {
            label(for: key)
                .frame(maxWidth: .infinity, minHeight: 56, maxHeight: 72)
                .contentShape(Rectangle())
        }
        .buttonStyle(KeypadButtonStyle())
        .accessibilityLabel(accessibilityLabel(for: key))

        if key == .backspace {
            button
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5).onEnded { _ in onClear() })
                .accessibilityHint("Double-tap and hold to clear")
                .accessibilityAction(named: "Clear") { onClear() }
        } else {
            button
        }
    }

    @ViewBuilder
    private func label(for key: KeypadKey) -> some View {
        switch key {
        case .digit(let digit):
            Text(verbatim: "\(digit)")
        case .decimalSeparator:
            // Input is stored with "." internally, but the key shows the locale's separator.
            Text(verbatim: Locale.current.decimalSeparator ?? ".")
        case .backspace:
            Image(systemName: "delete.left")
        }
    }

    private func accessibilityLabel(for key: KeypadKey) -> String {
        switch key {
        case .digit(let digit): "\(digit)"
        case .decimalSeparator: "Decimal point"
        case .backspace: "Delete"
        }
    }
}

private struct KeypadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.title, design: .rounded, weight: .medium))
            .foregroundStyle(.primary)
            .background(
                Color.primary.opacity(configuration.isPressed ? 0.12 : 0.05),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.snappy(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    KeypadView(onKey: { print($0) })
}

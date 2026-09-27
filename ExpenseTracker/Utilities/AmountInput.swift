import Foundation

/// A key on the custom amount keypad.
enum KeypadKey: Hashable, Sendable {
    case digit(Int)
    case decimalSeparator
    case backspace
}

/// The keypad's editing logic as a pure value type, so it is fully unit-testable.
///
/// `text` always uses "." internally, whatever the locale. Only `displayString(locale:)`
/// localizes the grouping and decimal separator.
struct AmountInput: Equatable, Sendable {
    static let maxIntegerDigits = 7
    static let maxFractionDigits = 2

    private(set) var text: String = ""

    init() {}

    /// Prefills from an existing value, e.g. `expensetracker://add?amount=250.5`.
    init(decimal: Decimal) {
        guard decimal > 0 else { return }
        // Decimal's description is locale-independent and always uses ".".
        text = String(describing: decimal.rounded(scale: Self.maxFractionDigits))
    }

    var isEmpty: Bool { text.isEmpty }

    var decimalValue: Decimal {
        Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    mutating func apply(_ key: KeypadKey) {
        switch key {
        case .digit(let digit): appendDigit(digit)
        case .decimalSeparator: appendSeparator()
        case .backspace: if !text.isEmpty { text.removeLast() }
        }
    }

    mutating func clear() {
        text = ""
    }

    /// The text as the user sees it while typing: locale grouping on the integer part,
    /// with a trailing separator and partial decimals kept exactly as typed ("12." or "12.5").
    func displayString(locale: Locale = .current) -> String {
        guard !text.isEmpty else { return "0" }

        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        let integerValue = Int(parts[0]) ?? 0
        var result = integerValue.formatted(.number.locale(locale))

        if parts.count > 1 {
            result += locale.decimalSeparator ?? "."
            result += parts[1]
        }
        return result
    }

    private mutating func appendDigit(_ digit: Int) {
        guard (0...9).contains(digit) else { return }

        if let separatorIndex = text.firstIndex(of: ".") {
            let fractionCount = text.distance(from: separatorIndex, to: text.endIndex) - 1
            guard fractionCount < Self.maxFractionDigits else { return }
            text.append(String(digit))
        } else if text == "0" {
            text = String(digit)
        } else {
            guard text.count < Self.maxIntegerDigits else { return }
            text.append(String(digit))
        }
    }

    private mutating func appendSeparator() {
        guard !text.contains(".") else { return }
        text = text.isEmpty ? "0." : text + "."
    }
}

import Foundation

/// The currency used for display, taken from the device region
/// (e.g. INR in India, USD in the US). Phase 5 adds a user override.
enum AppCurrency {
    static var code: String { Locale.current.currency?.identifier ?? "USD" }
    static var symbol: String { Locale.current.currencySymbol ?? "$" }
}

extension Decimal {
    func currencyFormatted(code: String = AppCurrency.code) -> String {
        formatted(.currency(code: code))
    }

    func rounded(scale: Int, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }

    var doubleValue: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }
}

extension String {
    /// Trimmed text, or `nil` if nothing is left after trimming.
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

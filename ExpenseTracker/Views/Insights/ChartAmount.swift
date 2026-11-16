import Foundation

/// Short money labels for chart axes, where a full "₹12,500.00" doesn't fit.
enum ChartAmount {
    /// "₹12K", "₹1.5L" / "₹1.5M" depending on the locale.
    static func compact(_ value: Double) -> String {
        AppCurrency.symbol + value.formatted(.number.notation(.compactName))
    }
}

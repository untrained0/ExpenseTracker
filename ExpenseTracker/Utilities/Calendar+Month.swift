import Foundation

extension Calendar {
    /// The calendar month containing `date`, as a half-open interval `[start, end)`.
    func monthInterval(containing date: Date) -> DateInterval {
        dateInterval(of: .month, for: date)
            ?? DateInterval(start: startOfDay(for: date), duration: 86_400)
    }
}

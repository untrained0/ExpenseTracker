import UIKit

/// Imperative haptics for the rare cases where `.sensoryFeedback` can't be used.
/// For example, on save the sheet is dismissed in the same frame, so a trigger-based
/// modifier on that view would never fire.
@MainActor
enum Haptics {
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

import Foundation
import UserNotifications

/// Posts the "add this expense?" local notification and routes taps back into the app.
///
/// iOS decides how the banner is shown. While a Focus that silences this app is on, the
/// system holds it back by itself; `PendingTransactionStore`'s hold switch covers the
/// case where the user wants the prompt *after* the game rather than quietly during it.
@MainActor
final class TransactionPromptNotifier: NSObject, TransactionPrompting {
    private nonisolated static let pendingIDKey = "pendingID"

    /// Called when the user taps a prompt. The ID is `nil` for a multi-item summary.
    var onOpenPending: ((UUID?) -> Void)?

    /// Must be installed before launch finishes, so a tap that starts the app is delivered.
    func installAsDelegate() {
        UNUserNotificationCenter.current().delegate = self
    }

    func authorization() async -> PromptAuthorization {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func prompt(for pending: [PendingTransaction]) {
        guard let first = pending.first else { return }

        let content = UNMutableNotificationContent()
        content.sound = .default
        if pending.count == 1 {
            content.title = first.kind == .income ? "Add this income?" : "Add this expense?"
            content.body = String(first.message.prefix(160))
            content.userInfo = [Self.pendingIDKey: first.id.uuidString]
        } else {
            content.title = "\(pending.count) transactions to review"
            content.body = "Bank messages arrived while prompts were on hold. Tap to add them."
        }

        let request = UNNotificationRequest(identifier: first.id.uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension TransactionPromptNotifier: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        // Read the plain value here; the response itself must not cross actors.
        let idText = response.notification.request.content.userInfo[Self.pendingIDKey] as? String
        await MainActor.run {
            onOpenPending?(idText.flatMap(UUID.init(uuidString:)))
        }
    }

    /// Show the prompt even when the app is in the foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

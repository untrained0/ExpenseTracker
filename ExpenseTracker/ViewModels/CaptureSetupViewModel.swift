import Foundation
import Observation

/// State for the "Automatic capture" setup screen: notification permission and the
/// prompt hold.
@MainActor
@Observable
final class CaptureSetupViewModel {
    private(set) var authorization: PromptAuthorization = .notDetermined
    private(set) var isHoldingPrompts = false
    private(set) var pendingCount = 0

    @ObservationIgnored private let prompter: TransactionPrompting
    @ObservationIgnored private let pendingStore: PendingTransactionStore
    @ObservationIgnored private let captureService: TransactionCaptureService

    init(
        prompter: TransactionPrompting,
        pendingStore: PendingTransactionStore,
        captureService: TransactionCaptureService
    ) {
        self.prompter = prompter
        self.pendingStore = pendingStore
        self.captureService = captureService
    }

    func refresh() async {
        authorization = await prompter.authorization()
        isHoldingPrompts = pendingStore.isHoldingPrompts()
        pendingCount = pendingStore.all.count
    }

    func allowNotifications() async {
        await prompter.requestAuthorization()
        await refresh()
    }

    /// For a hold that got stuck, e.g. the "game closed" automation never ran.
    func releaseHeldPrompts() async {
        captureService.setHoldingPrompts(false)
        await refresh()
    }
}

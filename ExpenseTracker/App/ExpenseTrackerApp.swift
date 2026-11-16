import SwiftData
import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @State private var router = AppRouter.shared
    @State private var dashboardViewModel: DashboardViewModel
    @State private var insightsViewModel: InsightsViewModel
    @State private var captureSetupViewModel: CaptureSetupViewModel
    private let repository: ExpenseRepository
    private let pendingStore: PendingTransactionStore
    /// Held for the app's lifetime: it is the notification delegate, which iOS keeps weakly.
    private let promptNotifier: TransactionPromptNotifier

    init() {
        // Build the object graph once. App Intents reach the same singletons
        // (PersistenceController.shared / AppRouter.shared) directly. See docs/ARCHITECTURE.md §2.
        let repository = ExpenseRepository(context: PersistenceController.shared.mainContext)
        let pendingStore = PendingTransactionStore()
        let promptNotifier = TransactionPromptNotifier()
        // A prompt for one message opens straight on it. A summary prompt just opens the
        // app, where the dashboard lists everything that needs review.
        promptNotifier.onOpenPending = { id in
            guard let id, let pending = pendingStore.pending(id: id) else { return }
            AppRouter.shared.presentPending(pending)
        }
        promptNotifier.installAsDelegate()

        self.repository = repository
        self.pendingStore = pendingStore
        self.promptNotifier = promptNotifier
        _dashboardViewModel = State(
            initialValue: DashboardViewModel(repository: repository, pendingStore: pendingStore)
        )
        _insightsViewModel = State(initialValue: InsightsViewModel(repository: repository))
        _captureSetupViewModel = State(
            initialValue: CaptureSetupViewModel(
                prompter: promptNotifier,
                pendingStore: pendingStore,
                captureService: TransactionCaptureService(
                    repository: repository,
                    pendingStore: pendingStore,
                    prompter: promptNotifier
                )
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                repository: repository,
                pendingStore: pendingStore,
                dashboardViewModel: dashboardViewModel,
                insightsViewModel: insightsViewModel,
                captureSetupViewModel: captureSetupViewModel
            )
            .environment(router)
            .onOpenURL { url in
                router.handle(url: url)
            }
        }
        .modelContainer(PersistenceController.shared)
    }
}

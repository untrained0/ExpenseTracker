import SwiftData
import SwiftUI

@main
struct ExpenseTrackerApp: App {
    @State private var router = AppRouter.shared
    @State private var dashboardViewModel: DashboardViewModel
    private let repository: ExpenseRepository

    init() {
        // Build the object graph once. App Intents reach the same singletons
        // (PersistenceController.shared / AppRouter.shared) directly. See docs/ARCHITECTURE.md §2.
        let repository = ExpenseRepository(context: PersistenceController.shared.mainContext)
        self.repository = repository
        _dashboardViewModel = State(initialValue: DashboardViewModel(repository: repository))
    }

    var body: some Scene {
        WindowGroup {
            RootView(repository: repository, dashboardViewModel: dashboardViewModel)
                .environment(router)
                .onOpenURL { url in
                    router.handle(url: url)
                }
        }
        .modelContainer(PersistenceController.shared)
    }
}

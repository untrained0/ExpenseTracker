import SwiftUI

/// Hosts the dashboard and presents the Add Expense sheet whenever `AppRouter`
/// asks for it, whether from the in-app button, the Action Button intent, or a deep link.
struct RootView: View {
    let repository: ExpenseRepository
    let dashboardViewModel: DashboardViewModel

    @Environment(AppRouter.self) private var router
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var router = router

        DashboardView(viewModel: dashboardViewModel)
            .sheet(item: $router.addExpenseRequest) { request in
                AddExpenseView(
                    viewModel: AddExpenseViewModel(repository: repository, request: request)
                )
            }
            .onChange(of: scenePhase) { _, phase in
                // Picks up expenses saved by LogExpenseIntent while the app was in the
                // background, and rolls the month over at midnight on the 1st.
                if phase == .active {
                    dashboardViewModel.load()
                }
            }
    }
}

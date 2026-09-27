import Combine
import SwiftUI

struct DashboardView: View {
    let viewModel: DashboardViewModel

    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthSummaryCard(
                        monthTitle: viewModel.monthTitle,
                        total: viewModel.monthTotal,
                        count: viewModel.monthCount,
                        categoryTotals: viewModel.categoryTotals
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }

                if viewModel.sections.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.sections) { section in
                        daySection(section)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Expenses")
            .refreshable { viewModel.load() }
            .safeAreaInset(edge: .bottom) { addButton }
            .task { viewModel.load() }
            .onReceive(NotificationCenter.default.publisher(for: .expenseStoreDidChange)) { _ in
                withAnimation(.snappy) { viewModel.load() }
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func daySection(_ section: DaySection) -> some View {
        Section {
            ForEach(section.expenses) { expense in
                ExpenseRowView(expense: expense)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            viewModel.delete(expense)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        } header: {
            HStack {
                Text(section.title)
                Spacer()
                Text(section.total.currencyFormatted())
                    .monospacedDigit()
            }
            .textCase(nil)
        }
    }

    private var emptyState: some View {
        Section {
            ContentUnavailableView {
                Label("No expenses yet", systemImage: "tray")
            } description: {
                Text("Press the Action Button or tap Add Expense to log your first one.")
            }
            .listRowBackground(Color.clear)
        }
    }

    /// Sits at the bottom of the screen, where a thumb can reach it on the 6.9" display.
    private var addButton: some View {
        Button {
            router.presentAddExpense(source: .inApp)
        } label: {
            Label("Add Expense", systemImage: "plus")
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

#if DEBUG
#Preview {
    DashboardView(viewModel: DashboardViewModel(repository: PreviewData.repository))
        .environment(AppRouter())
}
#endif

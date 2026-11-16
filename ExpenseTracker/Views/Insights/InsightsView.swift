import Combine
import SwiftUI

/// Month-by-month analytics: totals, daily spending, category ranking, six-month trend.
struct InsightsView: View {
    let viewModel: InsightsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InsightsSummaryCard(
                    summary: viewModel.summary,
                    change: viewModel.changeFromPreviousMonth,
                    previousMonthName: viewModel.previousMonthName
                )

                if viewModel.summary.spent > 0 {
                    InsightsCard(title: "Daily spending") {
                        DailySpendChart(days: viewModel.summary.daily)
                    }
                    InsightsCard(title: "By category") {
                        CategoryBreakdownList(totals: viewModel.summary.categories)
                    }
                } else {
                    ContentUnavailableView {
                        Label("No spending in \(viewModel.monthTitle)", systemImage: "chart.bar")
                    } description: {
                        Text("Expenses you log this month will be broken down here.")
                    }
                }

                InsightsCard(title: "Last \(InsightsViewModel.trendMonthCount) months") {
                    MonthTrendChart(months: viewModel.trend, selectedMonth: viewModel.month)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { monthSwitcher }
        .task { viewModel.load() }
        .onReceive(NotificationCenter.default.publisher(for: .expenseStoreDidChange)) { _ in
            viewModel.load()
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

    /// At the bottom so changing month is a thumb action on the 6.9" display.
    private var monthSwitcher: some View {
        HStack {
            monthButton("Previous month", systemImage: "chevron.left") {
                viewModel.showPreviousMonth()
            }

            Text(viewModel.monthTitle)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .contentTransition(.numericText())

            monthButton("Next month", systemImage: "chevron.right") {
                viewModel.showNextMonth()
            }
            .disabled(!viewModel.canShowNextMonth)
        }
        .padding(.horizontal, 6)
        .frame(minHeight: 56)
        .background(.regularMaterial, in: Capsule())
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func monthButton(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.snappy) { action() }
        } label: {
            Image(systemName: systemImage)
                .font(.body.weight(.semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(title)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        InsightsView(viewModel: InsightsViewModel(repository: PreviewData.repository))
    }
}
#endif

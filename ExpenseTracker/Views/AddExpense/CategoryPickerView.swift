import SwiftUI

/// A horizontally scrolling row of category chips. The selected chip is scrolled
/// into view on appear, which matters when the category was preset by an intent.
struct CategoryPickerView: View {
    @Binding var selection: ExpenseCategory

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExpenseCategory.allCases) { category in
                        CategoryChip(category: category, isSelected: category == selection) {
                            selection = category
                        }
                        .id(category)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .onAppear {
                proxy.scrollTo(selection, anchor: .center)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.snappy) { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
        .sensoryFeedback(.selection, trigger: selection)
    }
}

private struct CategoryChip: View {
    let category: ExpenseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.title, systemImage: category.symbolName)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .frame(minHeight: 40)
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .background(
                    Capsule().fill(isSelected ? AnyShapeStyle(category.tint) : AnyShapeStyle(.fill.tertiary))
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    @Previewable @State var selection = ExpenseCategory.transport
    CategoryPickerView(selection: $selection)
}

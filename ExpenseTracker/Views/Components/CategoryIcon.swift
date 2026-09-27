import SwiftUI

/// A tinted category glyph on a soft rounded square.
struct CategoryIcon: View {
    let category: ExpenseCategory
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: category.symbolName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(
                category.tint.opacity(0.15),
                in: RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack {
        ForEach(ExpenseCategory.allCases) { CategoryIcon(category: $0, size: 32) }
    }
    .padding()
}

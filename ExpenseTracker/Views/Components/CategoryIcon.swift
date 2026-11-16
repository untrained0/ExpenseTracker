import SwiftUI

/// A tinted glyph on a soft rounded square. Used for categories, income, and queued messages.
struct CategoryIcon: View {
    let symbolName: String
    let tint: Color
    var size: CGFloat = 44

    init(symbolName: String, tint: Color, size: CGFloat = 44) {
        self.symbolName = symbolName
        self.tint = tint
        self.size = size
    }

    init(category: ExpenseCategory, size: CGFloat = 44) {
        self.init(symbolName: category.symbolName, tint: category.tint, size: size)
    }

    var body: some View {
        Image(systemName: symbolName)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                tint.opacity(0.15),
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

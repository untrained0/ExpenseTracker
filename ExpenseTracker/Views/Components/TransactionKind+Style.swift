import SwiftUI

extension TransactionKind {
    /// Only income has its own look. Expenses are drawn with their category's tint and symbol.
    static let incomeTint: Color = .mint
    static let incomeSymbolName = "arrow.down.left"
}

import Foundation
import Testing
@testable import ExpenseTracker

struct AmountInputTests {
    private func input(_ keys: KeypadKey...) -> AmountInput {
        var input = AmountInput()
        keys.forEach { input.apply($0) }
        return input
    }

    @Test func startsEmptyAndZero() {
        let input = AmountInput()
        #expect(input.isEmpty)
        #expect(input.decimalValue == 0)
        #expect(input.displayString(locale: Locale(identifier: "en_US")) == "0")
    }

    @Test func appendsDigits() {
        #expect(input(.digit(1), .digit(2), .digit(3)).text == "123")
    }

    @Test func replacesLeadingZero() {
        #expect(input(.digit(0), .digit(5)).text == "5")
        #expect(input(.digit(0), .digit(0)).text == "0")
    }

    @Test func separatorFirstInsertsZero() {
        #expect(input(.decimalSeparator, .digit(5)).text == "0.5")
    }

    @Test func ignoresSecondSeparator() {
        #expect(input(.digit(1), .decimalSeparator, .decimalSeparator, .digit(2)).text == "1.2")
    }

    @Test func limitsFractionDigits() {
        #expect(input(.digit(1), .decimalSeparator, .digit(2), .digit(3), .digit(4)).text == "1.23")
    }

    @Test func limitsIntegerDigits() {
        var amount = AmountInput()
        for _ in 0..<10 { amount.apply(.digit(9)) }
        #expect(amount.text.count == AmountInput.maxIntegerDigits)
    }

    @Test func backspaceAndClear() {
        var amount = input(.digit(4), .digit(2))
        amount.apply(.backspace)
        #expect(amount.text == "4")
        amount.clear()
        #expect(amount.isEmpty)
        amount.apply(.backspace) // no crash on empty
        #expect(amount.isEmpty)
    }

    @Test func decimalValueIsExact() {
        #expect(input(.digit(1), .digit(2), .decimalSeparator, .digit(5)).decimalValue == Decimal(string: "12.5"))
    }

    @Test func displayUsesLocaleGroupingAndKeepsPartialDecimals() {
        let amount = input(.digit(1), .digit(2), .digit(3), .digit(4), .digit(5), .decimalSeparator)
        #expect(amount.displayString(locale: Locale(identifier: "en_US")) == "12,345.")
        #expect(amount.displayString(locale: Locale(identifier: "de_DE")) == "12.345,")
    }

    @Test func displayUsesIndianGrouping() {
        let amount = input(.digit(1), .digit(2), .digit(3), .digit(4), .digit(5), .digit(6), .digit(7))
        #expect(amount.displayString(locale: Locale(identifier: "en_IN")) == "12,34,567")
    }

    @Test func prefillFromDecimal() {
        // Compare values, not text: Decimal may print "250.5" or "250.50" after rounding.
        #expect(AmountInput(decimal: Decimal(string: "250.5")!).decimalValue == Decimal(string: "250.5"))
        #expect(AmountInput(decimal: Decimal(string: "9.999")!).decimalValue == 10)
        #expect(AmountInput(decimal: 0).isEmpty)
    }
}

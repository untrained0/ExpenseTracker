import Foundation
import Testing
@testable import ExpenseTracker

struct TransactionMessageParserTests {
    private func parse(_ message: String) -> ParsedTransaction? {
        TransactionMessageParser.parse(message)
    }

    // MARK: Debits

    @Test func upiDebitWithHandle() {
        let parsed = parse("Rs.250.00 debited from A/c XX1234 on 15-11-26 to VPA swiggy@icici (UPI Ref No 123456789012). Not you? Call 18002586161")
        #expect(parsed == ParsedTransaction(kind: .expense, amount: 250, currencyCode: "INR", merchant: "Swiggy"))
    }

    @Test func sentToMerchant() {
        let parsed = parse("Sent Rs.120.00 From HDFC Bank A/C *1234 To ZOMATO On 15/11/26 Ref 4321987650 Not You? Call 18002586161")
        #expect(parsed?.kind == .expense)
        #expect(parsed?.amount == 120)
        #expect(parsed?.merchant == "Zomato")
    }

    @Test func cardSpendIgnoresAvailableLimit() {
        let parsed = parse("INR 1,499.00 spent on ICICI Bank Card XX1234 on 15-Nov-26 at AMAZON PAY INDIA. Avl Lmt: INR 85,000.00. To dispute, call 18002662")
        #expect(parsed?.kind == .expense)
        #expect(parsed?.amount == 1_499)
        #expect(parsed?.merchant == "Amazon Pay India")
    }

    @Test func debitWithInfoFieldIgnoresBalance() {
        let parsed = parse("Your A/c XX1234 is debited with INR 500.00 on 15-11-2026. Info: UPI/P2M/630112345678/Uber India. Avl Bal INR 12,345.00")
        #expect(parsed?.amount == 500)
        #expect(parsed?.merchant == "Uber India")
    }

    @Test func amountWithoutCurrencyMarker() {
        let parsed = parse("Dear UPI user A/C X1234 debited by 500.0 on date 15Nov26 trf to SWIGGY Refno 630112345678. If not u? call 1800111109. -SBI")
        #expect(parsed == ParsedTransaction(kind: .expense, amount: 500, currencyCode: nil, merchant: "Swiggy"))
    }

    @Test func rupeeSymbolAndIndianGrouping() {
        let parsed = parse("You paid ₹1,02,345.50 to Sharma Furniture via UPI.")
        #expect(parsed?.amount == Decimal(string: "102345.50"))
        #expect(parsed?.merchant == "Sharma Furniture")
    }

    @Test func balanceBeforeTheAmountIsSkipped() {
        let parsed = parse("Avl Bal Rs 9,000.00. Rs 200 withdrawn from A/c XX1234 at SBI ATM MG ROAD on 15Nov26")
        #expect(parsed?.amount == 200)
    }

    // MARK: Credits

    @Test func salaryCredit() {
        let parsed = parse("Dear Customer, Rs 45,000.00 credited to your A/c XX1234 on 01-11-26 by NEFT from ACME CORP. Avl Bal Rs 1,02,345.67")
        #expect(parsed == ParsedTransaction(kind: .income, amount: 45_000, currencyCode: "INR", merchant: "Acme Corp"))
    }

    @Test func firstVerbDecidesTheDirection() {
        let debit = parse("Rs 500 debited from A/c XX12 and credited to merchant@upi")
        let credit = parse("Rs 500 credited to A/c XX12, debited from sender A/c XX99")
        #expect(debit?.kind == .expense)
        #expect(credit?.kind == .income)
    }

    // MARK: Needs review

    @Test func debitWithoutAmountStillCounts() {
        let parsed = parse("Your A/c XX1234 has been debited. Check the app for details.")
        #expect(parsed?.kind == .expense)
        #expect(parsed?.amount == nil)
    }

    @Test func foreignCurrencyIsReported() {
        let parsed = parse("USD 12.99 spent on HDFC Bank Card x1234 at NETFLIX.COM on 2026-11-15")
        #expect(parsed?.amount == Decimal(string: "12.99"))
        #expect(parsed?.currencyCode == "USD")
    }

    // MARK: Not transactions

    @Test(arguments: [
        "123456 is your OTP for txn of Rs 500.00 at Amazon. Do not share it with anyone.",
        "Get Rs 500 cashback on your next recharge! Offer valid till Sunday.",
        "Rahul has requested Rs 300 from you on UPI. Pay before 16-Nov.",
        "Rs 999 will be debited from A/c XX1234 on 20-Nov for your Netflix autopay.",
        "Your txn of Rs 750 at BigBasket failed. Any amount debited will be reversed.",
        "Statement for card XX1234: total due Rs 5,400, due on 25-Nov.",
        "We have received your request. Our team will contact you.",
        "Hey, are we still on for dinner tonight?",
        "",
    ])
    func ignoresMessagesThatAreNotCompletedTransactions(message: String) {
        #expect(parse(message) == nil)
    }
}

struct MerchantCategorizerTests {
    @Test func knownMerchants() {
        #expect(MerchantCategorizer.category(merchant: "Swiggy", message: "") == .food)
        #expect(MerchantCategorizer.category(merchant: "Uber India", message: "") == .transport)
        #expect(MerchantCategorizer.category(merchant: "Amazon Pay India", message: "") == .shopping)
        #expect(MerchantCategorizer.category(merchant: "Apollo Pharmacy", message: "") == .health)
    }

    @Test func shortKeywordsMustBeWholeWords() {
        #expect(MerchantCategorizer.category(merchant: "Ola", message: "") == .transport)
        #expect(MerchantCategorizer.category(merchant: "Coca Cola Store", message: "") == .other)
    }

    @Test func unknownMerchantDoesNotFallBackToTheMessage() {
        let message = "Rs 50 debited from your Airtel Payments Bank a/c to Ramesh"
        #expect(MerchantCategorizer.category(merchant: "Ramesh", message: message) == .other)
    }

    @Test func messageIsUsedWhenThereIsNoMerchant() {
        #expect(MerchantCategorizer.category(merchant: nil, message: "Rs 399 debited for Netflix subscription") == .entertainment)
    }
}

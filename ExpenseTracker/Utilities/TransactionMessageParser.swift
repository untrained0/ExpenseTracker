import Foundation

/// What `TransactionMessageParser` could read out of a bank or UPI message.
struct ParsedTransaction: Equatable, Sendable {
    var kind: TransactionKind
    /// `nil` when the message clearly reports a transaction but the amount isn't readable.
    var amount: Decimal?
    /// ISO code when the message names a currency ("Rs", "INR", "₹" → "INR").
    var currencyCode: String?
    var merchant: String?
}

/// Reads debit and credit alerts ("Rs.250.00 debited from A/c XX1234 … to VPA swiggy@icici").
///
/// Pure text logic with no Apple-only dependencies, so it is unit-tested on Windows too.
/// It is intentionally conservative: anything that isn't a *completed* money movement
/// (OTPs, payment requests, "will be debited", failed transactions, offers) returns `nil`.
enum TransactionMessageParser {
    static func parse(_ message: String) -> ParsedTransaction? {
        let text = message
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, matches(ignorePattern, in: text).isEmpty else { return nil }

        let debit = matches(debitPattern, in: text).first
        let credit = matches(creditPattern, in: text).first
        let kind: TransactionKind
        switch (debit, credit) {
        case (nil, nil):
            return nil
        case (.some, nil):
            kind = .expense
        case (nil, .some):
            kind = .income
        case let (.some(debit), .some(credit)):
            // "Rs 500 debited from A/c X and credited to merchant": the first verb is ours.
            kind = debit.location <= credit.location ? .expense : .income
        }

        let found = amount(in: text)
        // Without an amount, only an unmistakable verb is worth bothering the user about.
        if found == nil, matches(strongPattern, in: text).isEmpty { return nil }

        return ParsedTransaction(
            kind: kind,
            amount: found?.value,
            currencyCode: found?.currencyCode,
            merchant: merchant(in: text, kind: kind)
        )
    }

    // MARK: - Patterns

    private static let ignorePattern =
        #"\b(?:otp|one[- ]time password|verification code|requested|has requested|payment request|collect request|failed|declined|unsuccessful|could not be|will be (?:auto[- ]?)?(?:debited|deducted|charged|credited|refunded|reversed)|due (?:on|by|date))\b"#
    private static let debitPattern =
        #"\b(?:debited|spent|paid|withdrawn|deducted|purchase|charged)\b|\bsent\s+(?:rs\.?|inr|₹)"#
    private static let creditPattern = #"\b(?:credited|received|deposited|refunded|refund of|cashback of)\b"#
    private static let strongPattern = #"\b(?:debited|credited|spent|withdrawn)\b"#

    private static let numberPattern = #"([0-9][0-9,]*(?:\.[0-9]{1,2})?)"#
    private static let currencyAmountPattern =
        #"(?<![a-z0-9])(rs\.?|inr|₹|usd|\$|eur|€|gbp|£|aed)\s*"# + numberPattern
    /// SBI style: "A/C X1234 debited by 500.0 on date …" with no currency marker at all.
    private static let bareAmountPattern = #"\b(?:debited|credited)\s+(?:by|for|with|of)\s+"# + numberPattern

    /// Where a merchant name ends.
    private static let nameEnd =
        #"(?=\s+on\b|\s+at\b|\s*[.,;:(]|\s+avl\b|\s+ref|\s+upi\b|\s+via\b|\s+from\b|\s+using\b|\s+thru\b|\s+txn|\s+not you|\s+-|\s*$)"#
    private static let namePattern = #"([a-z][a-z0-9 &'*_-]{1,40}?)"# + nameEnd
    private static let handlePattern = #"(?:vpa\s+)?([a-z0-9._-]+)@[a-z][a-z0-9]*"#

    /// First words that mean the phrase after "to"/"from"/"by" isn't a merchant
    /// ("credited to your A/c", "To dispute, call …", "by NEFT").
    private static let notAMerchant: Set<String> = [
        "your", "a", "ac", "acc", "account", "mobile", "card", "bank", "vpa", "the", "dispute",
        "block", "report", "know", "check", "view", "stop", "avoid", "call", "sms", "you", "us",
        "our", "be", "get", "this", "is", "an", "it", "any", "register", "activate", "avail",
        "continue", "click", "visit", "login", "pay", "my", "linked", "beneficiary", "neft",
        "imps", "upi", "rtgs", "cash", "cheque", "transfer", "self",
    ]

    // MARK: - Amount

    private static func amount(in text: String) -> (value: Decimal, currencyCode: String?)? {
        let source = NSString(string: text)

        var previousEnd = 0

        for match in matches(currencyAmountPattern, in: text) {
            // "Avl Bal Rs 12,345.00" and "Total due Rs 5,000" are not the transaction amount.
            // Only the words since the previous amount count, so one balance can't disqualify
            // the amount that follows it.
            let start = max(previousEnd, match.location - 16)
            let before = source.substring(with: NSRange(location: start, length: match.location - start)).lowercased()
            previousEnd = match.location + match.length
            if ["bal", "lmt", "limit", "due", "outstanding"].contains(where: before.contains) { continue }

            if let value = decimal(match.groups[2]) {
                return (value, currencyCode(for: match.groups[1]))
            }
        }

        if let match = matches(bareAmountPattern, in: text).first, let value = decimal(match.groups[1]) {
            return (value, nil)
        }
        return nil
    }

    private static func decimal(_ text: String?) -> Decimal? {
        guard let text else { return nil }
        let digits = text.replacingOccurrences(of: ",", with: "")
        guard let value = Decimal(string: digits, locale: Locale(identifier: "en_US_POSIX")), value > 0 else {
            return nil
        }
        return value
    }

    private static func currencyCode(for marker: String?) -> String? {
        switch marker?.lowercased() {
        case "rs", "rs.", "inr", "₹": "INR"
        case "usd", "$": "USD"
        case "eur", "€": "EUR"
        case "gbp", "£": "GBP"
        case "aed": "AED"
        default: nil
        }
    }

    // MARK: - Merchant

    private static func merchant(in text: String, kind: TransactionKind) -> String? {
        let prepositions = kind == .expense ? "(?:to|at)" : "(?:from|by)"

        // A UPI handle is the most reliable name: "to VPA swiggy@icici".
        for match in matches(#"\b"# + prepositions + #"\s+"# + handlePattern, in: text) {
            if let name = cleanHandle(match.groups[1]) { return name }
        }

        var phrasePatterns: [String] = []
        if kind == .expense {
            phrasePatterns.append(#"\bat\s+"# + namePattern)
            phrasePatterns.append(#"\bto\s+"# + namePattern)
        } else {
            phrasePatterns.append(#"\b(?:from|by)\s+"# + namePattern)
        }
        for pattern in phrasePatterns {
            for match in matches(pattern, in: text) {
                if let name = cleanName(match.groups[1]) { return name }
            }
        }

        // "Info: UPI/P2M/123456/Uber India"
        if let info = matches(#"\binfo[:\s-]+([^.]+)"#, in: text).first?.groups[1] {
            let last = info.split(separator: "/").last.map(String.init)
            if let name = cleanName(last) { return name }
        }
        return nil
    }

    private static func cleanHandle(_ handle: String?) -> String? {
        guard let handle else { return nil }
        // Handles such as "paytmqr2810050501011abc" or a phone number aren't a readable name.
        guard handle.filter(\.isNumber).count <= 3 else { return nil }
        let words = handle.replacingOccurrences(of: "[._-]+", with: " ", options: .regularExpression)
        return cleanName(words)
    }

    private static func cleanName(_ raw: String?) -> String? {
        guard let name = raw?.trimmingCharacters(in: .whitespaces), name.count >= 2 else { return nil }
        guard name.contains(where: \.isLetter) else { return nil }
        let firstWord = name.lowercased().split(separator: " ").first.map(String.init) ?? ""
        guard !notAMerchant.contains(firstWord) else { return nil }

        // Banks shout ("AMAZON PAY INDIA"). Leave mixed case alone, it's usually deliberate.
        let isSingleCase = name == name.uppercased() || name == name.lowercased()
        return isSingleCase ? name.capitalized : name
    }

    // MARK: - Regex helper

    private struct Match {
        let location: Int
        let length: Int
        /// Capture groups, with the whole match at index 0.
        let groups: [String?]
    }

    /// The regex is built per call: this runs once per incoming message, and it avoids
    /// sharing a non-`Sendable` regex object across actors.
    private static func matches(_ pattern: String, in text: String) -> [Match] {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return []
        }
        let source = NSString(string: text)
        return regex.matches(in: text, range: NSRange(location: 0, length: source.length)).map { result in
            Match(
                location: result.range.location,
                length: result.range.length,
                groups: (0..<result.numberOfRanges).map { index in
                    let range = result.range(at: index)
                    return range.location == NSNotFound ? nil : source.substring(with: range)
                }
            )
        }
    }
}

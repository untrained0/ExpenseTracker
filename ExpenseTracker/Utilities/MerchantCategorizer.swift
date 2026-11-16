import Foundation

/// Guesses a spending category from a merchant name or message text.
///
/// Deliberately a small keyword table rather than anything clever: a wrong guess is easy
/// to see in the list, and unknown merchants fall back to `.other`.
enum MerchantCategorizer {
    /// Order matters: the first category with a hit wins ("primevideo" before "amazon").
    private static let keywords: [(category: ExpenseCategory, words: [String])] = [
        (.entertainment, ["netflix", "spotify", "hotstar", "bookmyshow", "primevideo", "youtube", "pvr", "inox", "steam", "playstation", "xbox", "movie", "cinema"]),
        (.food, ["swiggy", "zomato", "restaurant", "cafe", "dominos", "mcdonalds", "kfc", "starbucks", "pizza", "eatclub", "bakery", "dhaba", "biryani", "kitchen", "foods"]),
        (.groceries, ["bigbasket", "blinkit", "zepto", "dmart", "instamart", "grofers", "grocery", "groceries", "jiomart", "supermarket", "kirana", "provision"]),
        (.transport, ["uber", "ola", "rapido", "metro", "fuel", "petrol", "petroleum", "hpcl", "bpcl", "iocl", "indianoil", "fastag", "parking", "toll"]),
        (.travel, ["makemytrip", "irctc", "indigo", "airindia", "vistara", "redbus", "goibibo", "cleartrip", "hotel", "oyo", "airbnb", "airlines", "railway"]),
        (.health, ["pharmacy", "pharmeasy", "apollo", "1mg", "hospital", "clinic", "medplus", "netmeds", "medical", "diagnostics", "chemist"]),
        (.education, ["udemy", "coursera", "school", "college", "tuition", "byjus", "unacademy", "university", "academy"]),
        (.bills, ["electricity", "recharge", "airtel", "jio", "vodafone", "bsnl", "broadband", "bill", "billpay", "dth", "gas", "insurance", "lic", "bescom", "tatapower", "postpaid", "prepaid"]),
        (.shopping, ["amazon", "flipkart", "myntra", "ajio", "meesho", "nykaa", "croma", "decathlon", "ikea", "lifestyle"]),
    ]

    /// The merchant is checked first. The whole message is only a fallback, because it
    /// also contains the bank's own wording.
    static func category(merchant: String?, message: String) -> ExpenseCategory {
        if let merchant {
            return match(merchant) ?? .other
        }
        return match(message) ?? .other
    }

    private static func match(_ text: String) -> ExpenseCategory? {
        let tokens = text.lowercased()
            .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
            .map(String.init)
        guard !tokens.isEmpty else { return nil }

        for entry in keywords {
            for word in entry.words where tokens.contains(where: { matches(token: $0, word: word) }) {
                return entry.category
            }
        }
        return nil
    }

    /// Short keywords ("ola", "gas") must be a whole word, otherwise "cola" would be a cab.
    /// Longer ones may sit inside a token ("swiggyinstamart").
    private static func matches(token: String, word: String) -> Bool {
        token == word || (word.count >= 5 && token.contains(word))
    }
}

import Foundation

/// The review queue for bank messages that couldn't be logged automatically, plus the
/// "hold prompts" switch used while a game (or any Focus) is active.
///
/// Backed by `UserDefaults` rather than SwiftData: the queue is small and short-lived,
/// and keeping it out of the schema means no migration and no CloudKit sync of raw
/// bank messages. State lives entirely in `defaults`, so the app and its intents can
/// each create their own instance.
@MainActor
final class PendingTransactionStore {
    /// A hold that was never released (the "game closed" automation didn't run) expires
    /// after this long, so prompts can't stay silent forever.
    static let maxHoldDuration: TimeInterval = 6 * 3_600
    /// Banks sometimes deliver the same alert twice within a few minutes.
    static let duplicateWindow: TimeInterval = 10 * 60
    private static let rememberedMessageLimit = 30

    private static let queueKey = "pendingTransactions"
    private static let holdStartKey = "promptHoldStartedAt"
    private static let recentMessagesKey = "recentCapturedMessages"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: Queue

    /// Oldest first.
    var all: [PendingTransaction] {
        guard let data = defaults.data(forKey: Self.queueKey) else { return [] }
        return (try? JSONDecoder().decode([PendingTransaction].self, from: data)) ?? []
    }

    func pending(id: UUID) -> PendingTransaction? {
        all.first { $0.id == id }
    }

    func enqueue(_ pending: PendingTransaction) {
        save(all + [pending])
    }

    func remove(id: UUID) {
        save(all.filter { $0.id != id })
    }

    /// Marks every held-back entry as announced and returns the ones that were waiting.
    func takeUnannounced() -> [PendingTransaction] {
        var queue = all
        let waiting = queue.filter { !$0.isAnnounced }
        guard !waiting.isEmpty else { return [] }
        for index in queue.indices { queue[index].isAnnounced = true }
        save(queue)
        return waiting
    }

    private func save(_ queue: [PendingTransaction]) {
        if let data = try? JSONEncoder().encode(queue) {
            defaults.set(data, forKey: Self.queueKey)
        }
        NotificationCenter.default.post(name: .expenseStoreDidChange, object: nil)
    }

    // MARK: Prompt hold

    func isHoldingPrompts(now: Date = .now) -> Bool {
        guard let start = defaults.object(forKey: Self.holdStartKey) as? Date else { return false }
        return now.timeIntervalSince(start) < Self.maxHoldDuration
    }

    func setHoldingPrompts(_ hold: Bool, now: Date = .now) {
        if hold {
            defaults.set(now, forKey: Self.holdStartKey)
        } else {
            defaults.removeObject(forKey: Self.holdStartKey)
        }
    }

    // MARK: Duplicates

    /// Records the message and reports whether the same text was already seen recently.
    func isDuplicate(message: String, now: Date = .now) -> Bool {
        let key = message.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        var recent = (defaults.dictionary(forKey: Self.recentMessagesKey) as? [String: Date]) ?? [:]
        recent = recent.filter { now.timeIntervalSince($0.value) < Self.duplicateWindow }

        let seen = recent[key] != nil
        recent[key] = now
        if recent.count > Self.rememberedMessageLimit {
            let newest = recent.sorted { $0.value > $1.value }.prefix(Self.rememberedMessageLimit)
            recent = Dictionary(uniqueKeysWithValues: newest.map { ($0.key, $0.value) })
        }
        defaults.set(recent, forKey: Self.recentMessagesKey)
        return seen
    }
}

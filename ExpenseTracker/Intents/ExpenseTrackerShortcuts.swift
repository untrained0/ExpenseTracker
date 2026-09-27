import AppIntents

/// Publishes App Shortcuts. These show up automatically, with no user setup, in:
/// - Settings → Action Button → Shortcut → **Expense Tracker**
/// - the Shortcuts app, Spotlight, and Siri
///
/// Rules: every phrase must contain `\(.applicationName)`. Phrases may include an
/// `AppEnum` parameter (`\(\.$category)`), which Siri fills from the spoken words.
struct ExpenseTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Add an expense in \(.applicationName)",
                "New \(.applicationName) expense",
                "Open \(.applicationName) keypad",
            ],
            shortTitle: "Add Expense",
            systemImageName: "plus.circle.fill"
        )

        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: [
                "Log an expense in \(.applicationName)",
                "Log \(\.$category) expense in \(.applicationName)",
                "Quick log in \(.applicationName)",
            ],
            shortTitle: "Quick Log",
            systemImageName: "bolt.circle.fill"
        )
    }

    static var shortcutTileColor: ShortcutTileColor { .teal }
}

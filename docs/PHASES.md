# Phases

Each phase ends in a shippable, testable state. Tick boxes as work lands, and record details in [MEMORY.md](MEMORY.md).

Legend: ✅ done · 🟡 in progress · ⬜ not started

---

## Phase 0: Foundation & documentation ✅

**Goal:** A repo that another developer (or AI) can pick up cold.

- [x] Project docs: README, MEMORY, PHASES, DESIGN, RULES, ARCHITECTURE, SETUP
- [x] XcodeGen `project.yml` (app + unit-test targets, iOS 18.0, Swift 5 mode + complete concurrency checking)
- [x] Info.plist with URL scheme, privacy manifest, asset catalog skeleton
- [x] Folder structure matching MVVM layers
- [x] Windows testing: `Package.swift` runs the platform-independent logic tests with `swift test`
- [x] CI: `.github/workflows/ios.yml` builds the full app on a GitHub-hosted Mac, runs all tests on an iPhone Simulator, and uploads screenshots
- [x] git repo (`main`), `.gitattributes` forcing LF
- [x] Push to GitHub (https://github.com/untrained0/ExpenseTracker)
- [x] First green CI run (#3, `45723f9`)
- [x] CI builds an unsigned `.ipa` for sideloading onto the iPhone 17 Pro from Windows
- [ ] First sideload install and the Phase 2 device checklist (docs/SETUP.md §7)

**Done when:** `xcodegen generate` produces a project that opens in Xcode.

---

## Phase 1: Core data & UI ✅ (code written, pending first Xcode build)

**Goal:** Log and review expenses entirely inside the app.

- [x] `Expense` SwiftData model (id, amount `Decimal`, date, category, optional note). CloudKit-ready.
- [x] `ExpenseCategory` enum with 10 categories, SF Symbols, tints
- [x] `PersistenceController` (shared on-disk container + in-memory factory for tests/previews)
- [x] `ExpenseRepository` (fetch month, fetch recent, add, delete, change notification)
- [x] `DashboardViewModel` + `DashboardView`: month total, count, category breakdown bar, day-grouped recent list, swipe-to-delete, pull-to-refresh, empty state
- [x] `AddExpenseViewModel` + `AddExpenseView`: big amount display with caret, custom keypad, category chips, note, date, save
- [x] `AmountInput` pure value type (digit limits, single separator, 2 decimals, backspace, long-press clear)
- [x] Unit tests: AmountInput, DashboardViewModel, ExpenseRepository, AppRouter

**Done when:** You can add, view, and delete expenses on a device, the month total is correct, and tests pass.

---

## Phase 2: Action Button & App Intents ✅ (code written, pending device test)

**Goal:** Log an expense from the Action Button in about 2 seconds.

- [x] `AppRouter` (single source of truth for "show Add Expense")
- [x] `AddExpenseIntent`: `openAppWhenRun = true`, deep-links to the keypad, optional category preset
- [x] `LogExpenseIntent`: runs without opening the app. Prompts for amount and category, saves, returns dialog + snippet view
- [x] `ExpenseSnippetView`: Siri/Shortcuts result card with the month total
- [x] `ExpenseTrackerShortcuts` (`AppShortcutsProvider`) so both intents appear in the Action Button picker with no manual Shortcut creation
- [x] URL scheme `expensetracker://add?category=&amount=`

**Done when:**
1. Settings → Action Button → Shortcut → Expense Tracker → *Add Expense* opens the keypad with the amount active, from both cold start and background.
2. *Quick Log* logs an expense without opening the app, and the dashboard reflects it next time it opens.

---

## Phase 3: Editing & insights ⬜

- [ ] Tap a row to edit (reuse `AddExpenseView` in edit mode: `AddExpenseViewModel(expense:)`)
- [ ] Undo toast after delete / after save from the Action Button
- [ ] Month switcher (previous months) on the dashboard
- [ ] Insights screen with Swift Charts: daily spend bars, category donut, month-over-month
- [ ] Search and category filter (`.searchable`)
- [ ] Liquid Glass polish on iOS 26 (`.glassEffect`, `.buttonStyle(.glassProminent)` behind `if #available(iOS 26, *)`)
- [ ] Hardware keyboard input on the keypad (`.focusable()` + `.onKeyPress`)

---

## Phase 4: System surfaces ⬜

- [ ] **App Group** (`group.<bundle-id>`) and move the store into it (`ModelConfiguration(groupContainer:)`), with a one-time migration of the existing store file
- [ ] Widget extension: home and lock screen widgets (month total, "Add" button)
- [ ] **Control Center control** (`ControlWidgetButton` running `AddExpenseIntent`). On iOS 18+ this can be assigned **directly** to the Action Button as a Control, which skips the Shortcut layer.
- [ ] Interactive widget button to log a "repeat last expense"
- [ ] Move shared intent code into a framework or shared target membership so the widget extension can use it

---

## Phase 5: Power features ⬜

- [ ] Monthly budget (overall + per category) with progress on the dashboard
- [ ] Recurring expenses (rent, subscriptions)
- [ ] Currency setting (override device locale) and multi-currency display
- [ ] CSV export via `ShareLink` / `Transferable`
- [ ] iCloud sync (`ModelConfiguration(cloudKitDatabase: .automatic)`). The model is already CloudKit-compatible.
- [ ] iOS 26 **interactive snippets** (`SnippetIntent`) for `LogExpenseIntent`: category buttons and an Undo button inside the Siri card. Check the API against the current SDK before building.
- [ ] `IndexedEntity` / Spotlight for past expenses. Apple Intelligence "Log expense" schemas if available.

---

## Phase 6: Release ⬜

- [ ] Accessibility audit (VoiceOver, Dynamic Type up to AX5, Reduce Motion, contrast)
- [ ] Localization (String Catalog), including Indian numbering (`en_IN`) grouping checks
- [ ] App icon (light / dark / tinted)
- [ ] Privacy nutrition label: "Data Not Collected"
- [ ] TestFlight beta → App Store submission

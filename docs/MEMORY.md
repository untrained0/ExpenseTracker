# Memory: implementation log

> The single source of truth for **what exists right now**. Read this first. Update it after every change (docs/RULES.md §8).

## Status snapshot

| | |
|---|---|
| Last updated | 2026-09-27 |
| Active phase | Phases 0–2 complete and building. **Next: on-device Action Button test**, then Phase 3 |
| Build verified? | ✅ Compiles in CI (`macos-26`, Xcode 26), run #3 on `45723f9`. Not yet run on a physical iPhone |
| Tests | 25 Swift Testing cases: all pass on the iOS Simulator (CI). The 17 logic tests also pass on Windows |
| Min iOS / SDK | iOS 18.0 / Xcode 26 (iOS 26 SDK) |

## What's implemented

### Phase 0: Foundation
- `project.yml` (XcodeGen): app target `ExpenseTracker` (iPhone only, portrait), test target `ExpenseTrackerTests`, Swift 5 mode + `SWIFT_STRICT_CONCURRENCY=complete`, bundle ID `com.yourname.expensetracker` (placeholder).
- `Resources/Info.plist`: hand-maintained (`GENERATE_INFOPLIST_FILE=NO`), with the URL scheme `expensetracker`.
- `Resources/PrivacyInfo.xcprivacy`: UserDefaults reason CA92.1, no tracking, no collected data.
- `Resources/Assets.xcassets`: AccentColor (teal `#0FA3A3` / dark `#2DD4BF`), empty AppIcon slots (light/dark/tinted).
- **Testing from Windows** (added 2026-09-27, details in docs/SETUP.md §6):
  - `Package.swift`: SwiftPM package that compiles only the platform-independent files **in place** (`AppRouter`, `ExpenseCategory`, `AmountInput`, `Calendar+Month`, `Formatters`) as module `ExpenseTracker`, plus `AmountInputTests` and `AppRouterTests`. Run with `swift test`. New Apple-independent files must be added to its `sources`.
  - `.github/workflows/ios.yml`: runs on `macos-26`. XcodeGen → `xcodebuild test` on an iPhone 17 Pro Max simulator (falls back to any iPhone), then installs the app and takes 3 screenshots (dashboard, Add Expense via deep link, dark mode). Artifacts: `screenshots`, `test-results`.
  - Swift toolchain 6.4.0 installed on the dev PC via winget. VS Build Tools 2022 (MSVC + SDK 10.0.26100) was already present.
  - git on `main`, `.gitattributes` forces LF. Remote: **https://github.com/untrained0/ExpenseTracker** (public, so CI minutes are free). First push: `90dea31`.

### Phase 1: Core data & UI
| File | What it does |
|---|---|
| `Models/Expense.swift` | `@Model`: `id: UUID`, `amount: Decimal`, `date`, `categoryRawValue: String`, `note: String?`, `createdAt`. Computed `category` and `displayTitle`. `#Index` on `date`. CloudKit-compatible. |
| `Models/ExpenseCategory.swift` | 10 cases: food, groceries, transport, bills, shopping, entertainment, health, travel, education, other. `title`, `symbolName`. |
| `Services/PersistenceController.swift` | `shared` on-disk container. `makeContainer(inMemory:)` for tests and previews (unique name per instance). |
| `Services/ExpenseRepository.swift` | `@MainActor`. `expenses(in:)`, `recentExpenses(limit:)`, `total(in:)`, `add(...)` (rejects ≤ 0, trims note), `delete(_:)`. Rolls back on a failed save. Posts `.expenseStoreDidChange`. |
| `ViewModels/DashboardViewModel.swift` | Month total, count, `categoryTotals` (sorted, with share), `sections` (latest 50 grouped by day: Today / Yesterday / "Monday, 14 Sep"). Injectable `calendar` + `now`. |
| `ViewModels/AddExpenseViewModel.swift` | `amountInput`, `category` (request preset → last used → food), `date`, `note`. `save()` stores and remembers the category in UserDefaults. |
| `Utilities/AmountInput.swift` | Pure keypad logic: at most 7 integer and 2 decimal digits, leading-zero replacement, `.` → `0.`, one separator only, backspace, clear. Locale-aware `displayString`. |
| `Utilities/Formatters.swift` | `AppCurrency` (from the device locale), `Decimal.currencyFormatted()`, `.rounded(scale:)`, `.doubleValue`, `String.nilIfBlank`. |
| `Views/Dashboard/*` | `DashboardView` (inset list, summary card, day sections with totals, swipe-delete, pull-to-refresh, empty state, bottom "Add Expense" capsule), `MonthSummaryCard` (total + share bar + top-3 legend), `ExpenseRowView`. |
| `Views/AddExpense/*` | `AddExpenseView` (header ✕ / title / date, hero amount, note, chips, keypad, Save), `AmountDisplayView` (80 pt rounded, numericText transition, blinking caret), `KeypadView` (Grid 4×3, long-press ⌫ clears), `CategoryPickerView` (scrolls to selection). |
| `Views/Components/*` | `CategoryIcon`, `ExpenseCategory.tint`. |

### Phase 2: Action Button & App Intents
| File | What it does |
|---|---|
| `App/AppRouter.swift` | `@Observable` singleton. `presentAddExpense(category:amount:source:)` is a no-op if the sheet is already open. `handle(url:)` parses `expensetracker://add?category=&amount=`. |
| `App/RootView.swift` | `.sheet(item: $router.addExpenseRequest)` → `AddExpenseView`. Reloads the dashboard on `scenePhase == .active`. |
| `App/ExpenseTrackerApp.swift` | Builds the repository and dashboard VM once, injects the router, `.onOpenURL`. |
| `Intents/AddExpenseIntent.swift` | `openAppWhenRun = true`, optional `category` parameter → router. **The Action Button's primary path.** |
| `Intents/LogExpenseIntent.swift` | `openAppWhenRun = false`. Prompts for `amount: Double` and `category`, optional `note`. Converts to `Decimal` rounded to 2 places, saves, returns dialog + `ExpenseSnippetView` with the month total. |
| `Intents/ExpenseCategory+AppEnum.swift` | `AppEnum` conformance with literal titles and SF Symbols. |
| `Intents/ExpenseTrackerShortcuts.swift` | App Shortcuts "Add Expense" and "Quick Log" (with a category phrase). Tile color teal. |
| `Intents/ExpenseSnippetView.swift` | Result card: icon, amount, note/category, "This month" total. |

### Tests (`ExpenseTrackerTests/`)
- `AmountInputTests`: 12 cases, including en_US, de_DE, and en_IN display.
- `ExpenseStoreTests`: repository validation and trimming, month filtering, delete, dashboard totals, shares, day grouping, empty state, AddExpenseViewModel save + last-category memory.
- `AppRouterTests`: presenting, no double-present, deep-link parsing, invalid values, foreign URLs.

## Decisions log

| Date | Decision | Why |
|---|---|---|
| 2026-09-27 | Manual entry + Action Button instead of reading SMS or bank apps | iOS sandboxing prevents reading other apps' data or SMS |
| 2026-09-27 | `Decimal` for money, category stored as raw `String` | Exact arithmetic. Simple predicates. Renaming titles is safe |
| 2026-09-27 | CloudKit-compatible model from day one | iCloud sync in Phase 5 without a migration |
| 2026-09-27 | Repository + `@Observable` VMs instead of `@Query` in views | Requested MVVM. Testable without UI. Intents share the same write path |
| 2026-09-27 | Refresh via `NotificationCenter` (`.expenseStoreDidChange`) + `scenePhase` | Deterministic. Also covers background intent writes |
| 2026-09-27 | Router singleton that intents mutate | App Intents have no view hierarchy to inject into. Keeps intents UI-agnostic |
| 2026-09-27 | Two intents: open-app (A) and no-UI (B) | A is fastest for full control. B works without leaving the current app |
| 2026-09-27 | Custom keypad instead of `.decimalPad` | Always visible, bigger targets, no keyboard animation delay, so the amount is "focused" instantly |
| 2026-09-27 | `openAppWhenRun` rather than iOS 26 `supportedModes` | Works on the iOS 18 deployment target. Revisit when the minimum becomes iOS 26 |
| 2026-09-27 | XcodeGen instead of a committed `.xcodeproj` | Main dev machine is Windows. A hand-written `.pbxproj` would be fragile |
| 2026-09-27 | Windows testing = SwiftPM logic package + GitHub Actions macOS runner | Only the Apple-free code runs on Windows. The full compile needs macOS, so CI provides it without owning a Mac |
| 2026-09-27 | Swift 5 mode + complete concurrency checking (not Swift 6 mode) | Avoids hard errors from SwiftData/AppIntents SDK annotations while still surfacing issues as warnings |

## CI history

| Run | Commit | Result | Notes |
|---|---|---|---|
| #1 | `90dea31` | ❌ compile error | `LogExpenseIntent`: `.result(dialog:view:)` → "extra argument 'view'". Everything else compiled. |
| #2 | `30228ea` | ❌ compile error | Trailing-closure form → "no exact matches". **Root cause:** the snippet overloads of `.result` live in the AppIntents × SwiftUI cross-import overlay, which only loads when the file imports **both** modules. Fixed by adding `import SwiftUI` to `LogExpenseIntent.swift`. |

| #3 | `45723f9` | ✅ **green** | Full app compiles on Xcode 26 / iOS 26 SDK. All tests pass on the iPhone Simulator. Screenshots uploaded (dashboard, Add Expense via deep link, dark mode). |

**Harmless log noise:** "Failed to stat path … Application Support/default.store, Sandbox access to file-write-create denied" on the first launch in a fresh simulator. SwiftData creates the store right after. If it ever matters, pre-create `URL.applicationSupportDirectory` in `PersistenceController.makeContainer`.

**Windows logic tests:** 17/17 pass on Swift 6.4 (`scripts/test-windows.ps1`, 2026-09-27).

**CI diagnostics:** job logs need admin auth to download, but annotations on a public repo are readable without login (`GET /repos/untrained0/ExpenseTracker/check-runs/{job_id}/annotations`). On failure, the workflow re-publishes each compiler error plus the next 12 lines as `notice` annotations.

**Accepted warnings:** 10× "`KeyPath<Expense, Date>` does not conform to `Sendable`" come from Apple's `#Predicate` macro expansion in `ExpenseRepository.expenses(in:)`. This is an SDK issue we can't fix from our code. Revisit when moving to Swift 6 language mode.

## Known gaps / unverified

1. ~~Compile-time API doubts~~: resolved. CI #3 compiled `#Index`, `ShortcutTileColor.teal`, the `@Parameter` overloads, and the snippet result.
2. The Action Button flow hasn't been tested on a device (cold start and warm start). CI only checks the same code path through the deep link, which goes through `AppRouter`.
3. `LogExpenseIntent` writes while the app is backgrounded. The dashboard refreshes on the next activation (by design). Check there's no stale data after a warm resume.
4. The AppIcon has no artwork yet.
5. Currency always follows the device locale. There's no override yet (Phase 5).
6. No edit screen yet. Tapping a row does nothing (Phase 3).

## Next steps

1. Review the CI screenshots (Actions → latest run → Artifacts → `screenshots`) and note any visual issues.
2. On-device (needs a Mac, or a sideloaded build): assign the Action Button to "Add Expense" and to "Quick Log", then go through the Phase 2 "done when" checklist in PHASES.md.
3. Start Phase 3 (edit screen first).

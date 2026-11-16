# Memory: implementation log

> The single source of truth for **what exists right now**. Read this first. Update it after every change (docs/RULES.md §8).

## Status snapshot

| | |
|---|---|
| Last updated | 2026-11-16 |
| Active phase | Phases 0–2 complete. **Phase 2b (automatic capture) and the Phase 3 Insights screen are code-complete** (2026-11-16) and need an on-device run. Next: device checks, then the rest of Phase 3 |
| Build verified? | ✅ Compiles **locally on a Mac** (Xcode 27.2, iOS 27.2 SDK) for simulator and device, 2026-11-16. CI last ran on `ac3abd9`, before Phase 2b / Insights. ✅ Installed on the physical iPhone 17 Pro Max 2026-11-16 (launched there only with the 2026-11-13 build). Action Button and capture behaviour still untested on the device |
| Tests | 63 Swift Testing cases (8 suites): all pass on the iOS Simulator locally (Xcode 27.2, iPhone 18 Pro Max sim, 2026-11-16). 40 of them are logic tests that also run with `swift test` (passing on macOS; **not yet re-run on Windows or in CI** since the 2026-11-16 changes) |
| Min iOS / SDK | iOS 18.0. Builds against both the iOS 26 SDK (CI) and the iOS 27 SDK (local Mac) |

## What's implemented

### Phase 0: Foundation
- `project.yml` (XcodeGen): app target `ExpenseTracker` (iPhone only, portrait), test target `ExpenseTrackerTests`, Swift 5 mode + `SWIFT_STRICT_CONCURRENCY=complete`, bundle ID `com.untrained0.expensetracker` (changed from the `com.yourname` placeholder on 2026-09-27 so free-Apple-ID signing doesn't collide).
- **iPhone testing = Route A (sideload from Windows)**, decided 2026-09-27. Device: **iPhone 17 Pro** (has Action Button). The CI job `ipa` builds an unsigned Release `ExpenseTracker.ipa` (artifact `ExpenseTracker-ipa`, 30-day retention) and fails if `Metadata.appintents` is missing. The user installs with Sideloadly and a free Apple ID (7-day re-sign). Guide: docs/SETUP.md §7.
- **Superseded 2026-11-13 by Route C (direct from a Mac).** A Mac (macOS 27.2, Xcode 27.2) is now available, so builds go straight to the iPhone from Xcode with free-Apple-ID signing — same 7-day expiry, but no unsigned IPA or Sideloadly step, plus debugger and console access. Route A stays valid as the Windows fallback. Local setup: `brew install xcodegen`, `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`, `xcodegen generate`.
  - Signing team: **`NCDX6W65V3`** (Personal Team on the developer's free Apple ID). Now committed in `project.yml` so `xcodegen generate` no longer blanks it. Bundle ID `com.untrained0.expensetracker` registered without a collision.
  - Device: iPhone 17 Pro Max, UDID not recorded here because the repo is public — get it with `xcrun devicectl list devices` (MEMORY previously said "iPhone 17 Pro" — the actual device is the Pro Max; both have the Action Button).
  - One-time device prerequisites: Developer Mode on (Settings → Privacy & Security, needs a restart), then Settings → General → VPN & Device Management → Trust the developer certificate. Without the trust step the install succeeds but launch fails with `FBSOpenApplicationErrorDomain error 3` ("profile has not been explicitly trusted").
  - Non-Xcode install/launch loop, useful from this repo:
    `xcodebuild -project ExpenseTracker.xcodeproj -scheme ExpenseTracker -destination 'id=<UDID>' -allowProvisioningUpdates build` → `xcrun devicectl device install app --device <UDID> <path>/ExpenseTracker.app` → `xcrun devicectl device process launch --device <UDID> com.untrained0.expensetracker`. `-allowProvisioningUpdates` is what registers the device with the Personal Team; without it Xcode reports "Your team has no devices from which to generate a provisioning profile".
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

### Phase 2b: Automatic capture from bank messages (2026-11-16)

**How it works.** iOS doesn't let an app read SMS or other apps' notifications, so a Shortcuts *personal automation* ("When I get a message containing …", Run Immediately) passes the message text to `CaptureTransactionIntent`. The app then decides:

| Message | Result |
|---|---|
| Readable amount in the home currency, debit | Saved as an expense. Note = merchant, category guessed from the merchant. No prompt |
| Readable amount, credit | Saved as **income** (`kind == .income`). Not counted in spending totals |
| Clearly a debit/credit but no readable amount, or a foreign-currency amount | Goes to the **review queue** and a local notification asks the user to add it |
| OTP, offer, payment request, "will be debited", failed/declined, ordinary chat | Ignored |
| Same text again within 10 minutes | Ignored as a duplicate |

**Holding prompts during games.** `PendingTransactionStore` has a hold switch. While it's on, review-queue entries are stored unannounced; turning it off sends **one** notification for everything that waited. Two ways to flip it: `SetExpensePromptsIntent` in Shortcuts *App* automations (game Is Opened → hold on, Is Closed → hold off), or `ExpensePromptsFocusFilter` attached to a Gaming Focus. A hold that is never released expires after 6 hours, and the next capture releases the stale queue. Messages with a readable amount are still logged silently while holding.

| File | What it does |
|---|---|
| `Models/TransactionKind.swift` | `expense` / `income`. Stored through `Expense.kindRawValue` |
| `Models/Expense.swift` | **Schema change:** new `kindRawValue: String = "expense"` (+ computed `kind`, `record`). Additive with a default, so SwiftData migrates old stores automatically — verified by installing the pre-change build on the simulator, saving an expense, and upgrading in place. No `VersionedSchema` (nothing is released yet, RULES §2.5) |
| `Models/PendingTransaction.swift` | Codable review-queue entry: message text, optional amount (stored as text for exact `Decimal` round-trips), kind, merchant, category guess, `isAnnounced` |
| `Utilities/TransactionMessageParser.swift` | Pure. `parse(_:) -> ParsedTransaction?` (kind, amount, currency code, merchant). Tuned for Indian bank/UPI formats (Rs / INR / ₹, lakh grouping, "debited by 500.0" without a currency, VPA handles, `Info: UPI/…/Merchant`). Skips balance/limit/due amounts. The first debit/credit verb decides the direction |
| `Utilities/MerchantCategorizer.swift` | Pure keyword table → `ExpenseCategory`. Short keywords must be whole words. Falls back to `.other` |
| `Services/PendingTransactionStore.swift` | Review queue, prompt hold (`maxHoldDuration` 6 h), duplicate window (10 min). **UserDefaults-backed**, so the app and intents can each build their own instance. Posts `.expenseStoreDidChange` |
| `Services/TransactionCaptureService.swift` | The pipeline above: `capture(message:) -> CaptureOutcome`, `setHoldingPrompts(_:)` |
| `Services/TransactionPrompting.swift`, `TransactionPromptNotifier.swift` | Protocol + `UNUserNotificationCenter` implementation. It is the notification delegate: tapping a single-item prompt opens the Add sheet for that item via `AppRouter.presentPending` |
| `Intents/CaptureTransactionIntent.swift` | "Capture Bank Message", one `message: String` parameter. Returns a **value**, not a dialog (RULES §4.4 exception) |
| `Intents/SetExpensePromptsIntent.swift` | "Hold Expense Prompts", `hold: Bool` |
| `Intents/ExpensePromptsFocusFilter.swift` | `SetFocusFilterIntent` with `holdPrompts: Bool` |
| `Intents/TransactionCaptureService+Intents.swift` | `forIntents()` factory on the shared store |
| `ViewModels/CaptureSetupViewModel.swift`, `Views/Capture/CaptureSetupView.swift` | "Automatic capture" screen (envelope button, dashboard top-left): notification permission, setup steps, "Release held prompts now" |
| `Views/Dashboard/PendingTransactionRow.swift` | "Needs review" section at the top of the dashboard. Tap = add, swipe = ignore |
| `App/AppRouter.swift` | `AddExpenseRequest` gained `kind`, `note`, `date`, `pendingID`, `sourceMessage`; `presentPending(_:)` |
| `Views/AddExpense/AddExpenseView.swift` | Header title replaced by an **Expense / Income** segmented control. Income hides the category chips. When reviewing a queued message, its text is shown above the amount, and saving removes it from the queue |

Notification permission is requested from the setup screen, not at launch, so CI screenshots and first launch stay clean.

### Phase 3 (partial): Insights (2026-11-16)

| File | What it does |
|---|---|
| `Utilities/SpendingAnalytics.swift` | Pure aggregation over `TransactionRecord` values: `summary(of:in:calendar:now:)` → `MonthSummary` (spent, income, net, count, daily average over elapsed days, per-day series incl. empty days, category totals, largest expense), `monthlyTotals`, `change(from:to:)`, `categoryTotals`. `CategoryTotal` moved here from `DashboardViewModel` |
| `ViewModels/InsightsViewModel.swift` | Selected month (previous/next, never into the future), summary, 6-month trend, change vs previous month. One repository fetch per load |
| `Views/Insights/*` | `InsightsView` (chart button, dashboard top-right; month switcher in a bottom capsule), `InsightsSummaryCard`, `DailySpendChart` (Swift Charts columns, drag to read a day), `CategoryBreakdownList` (ranked bars, see Decisions), `MonthTrendChart` (selected month in accent, others gray), `InsightsCard`, `ChartAmount` |

The dashboard now treats income separately: month total, count, share bar and day totals are **spending only**; income rows are listed with a `+` and a mint arrow icon.

### Tests (`ExpenseTrackerTests/`)
- `TransactionMessageParserTests` (+ `MerchantCategorizerTests`): 11 bank formats, 9 non-transactions, categorizer edge cases. Runs on Windows.
- `SpendingAnalyticsTests`: summary, daily series, daily average, monthly totals, change. Runs on Windows.
- `TransactionCaptureTests` (Apple-only): auto-log debit/credit, ignore, duplicate window, review queue, foreign currency, hold → release as one prompt, hold expiry, review-and-save removes the queue entry, dashboard income handling, setup view model.
- `InsightsViewModelTests` (Apple-only): month load, comparison, navigation limits.
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

| 2026-11-16 | Automatic capture through a **Shortcuts Message automation → App Intent** (supersedes "manual entry only" for bank SMS) | Still no way to read SMS or notifications directly, but the automation hands us the text legally and can run without confirmation. Notifications from apps like GPay/PhonePe remain unreachable |
| 2026-11-16 | Auto-log silently; prompt only when the amount or currency is unclear | Matches the request ("add automatically, otherwise ask"). A prompt per bank SMS would be noise |
| 2026-11-16 | Credits are stored as income (`Expense.kindRawValue`) instead of a new model or an "Income" category | One list, one fetch, additive schema change. A category would pollute the picker and the spending shares |
| 2026-11-16 | Review queue in UserDefaults, not SwiftData | Small, short-lived, no schema or CloudKit impact; raw bank messages stay off iCloud |
| 2026-11-16 | Game detection = explicit hold switch driven by Shortcuts App automations or a Focus filter | An app can't see which app is in the foreground. A 6-hour expiry covers a release that never arrives |
| 2026-11-16 | Category breakdown is a ranked bar list, **not the donut** PHASES originally named | Ten categories don't read in a donut; bars on one baseline compare exactly, and the icon + name carry identity so it isn't colour-only |
| 2026-11-16 | Insights is pushed from a toolbar button rather than a tab bar | Keeps the dashboard's bottom edge for the one primary action (Add Expense) |

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
0. **Installed on the iPhone 2026-11-16 (Route C), not yet opened.** The build with capture and Insights is on the device, but the remote launch failed because the phone was locked, so the first launch on real data (and the `kindRawValue` migration of the on-device store) is still unobserved. Signing note: `codesign` needs the Mac's **login keychain password** to use the "Apple Development" key; from a non-interactive shell a missing approval shows up as `errSecInternalComponent`. It was approved on 2026-11-16; if the prompt returns, choose **Always Allow**. Route A (CI IPA + Sideloadly) avoids the Mac keychain entirely.
6. No edit screen yet. Tapping a row does nothing (Phase 3). This also means a wrongly categorised auto-logged expense can only be deleted and re-added.
7. **Automatic capture is untested on a device.** Simulator-verified: build, all unit tests, intent metadata (all three new intents are in `Metadata.appintents`), the Add sheet's Expense/Income control, the setup screen. **Not verified:** the Shortcuts Message automation actually delivering the SMS text to `CaptureTransactionIntent` (incl. bank short-code senders), the local notification and its tap routing, and `SetExpensePromptsIntent` from App automations.
8. **Focus filter release is an assumption.** `ExpensePromptsFocusFilter` relies on iOS calling `perform()` with default parameter values when the Focus turns off. The SDK headers don't state it and it hasn't been observed on a device. If it doesn't hold, use the App automations (the in-app setup screen lists those first) — the 6-hour expiry is the backstop.
9. The parser is tuned to common Indian bank/UPI wording and will miss formats it hasn't seen (they are ignored or queued, never mis-logged without an amount). Known soft spots: a credit-card bill "payment received" SMS is logged as income; when no merchant is found, the bank's own name in the message can sway the category (e.g. "Airtel Payments Bank" → Bills).
10. Insights and the new screens were checked on the iPhone 18 Pro Max simulator in light mode only. Not checked: dark mode, iPhone SE width (the Add sheet header now holds ✕ + segmented control + date), Dynamic Type, VoiceOver.
11. CI and Windows haven't run since these changes (nothing is pushed). `Package.swift` lists the new pure files; the Windows run is expected to pass but is unconfirmed.

## Next steps

1. Review the CI screenshots (Actions → latest run → Artifacts → `screenshots`) and note any visual issues.
2. On-device (needs a Mac, or a sideloaded build): assign the Action Button to "Add Expense" and to "Quick Log", then go through the Phase 2 "done when" checklist in PHASES.md.
3. On the iPhone: open **Automatic capture** (envelope button), allow notifications, create the Message automations ("debited", "credited", "spent") and the two App automations for games, then confirm gaps 7 and 8.
4. Continue Phase 3 (edit screen first — it also fixes gap 6 for auto-logged entries).

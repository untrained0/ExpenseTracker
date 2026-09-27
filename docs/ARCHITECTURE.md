# Architecture

## 1. Layers

```
┌──────────────────────────── App ─────────────────────────────┐
│ ExpenseTrackerApp ── RootView ── AppRouter.shared (@Observable)│
└───────────────┬───────────────────────────────▲──────────────┘
                │ creates                        │ sets state
┌───────────────▼──────────── Views ─────────────┴─────────────┐
│ DashboardView   AddExpenseView   (+ components)              │
└───────────────┬──────────────────────────────────────────────┘
                │ owns / observes
┌───────────────▼────────── ViewModels ────────────────────────┐   ┌──────── Intents ────────┐
│ DashboardViewModel   AddExpenseViewModel                     │   │ AddExpenseIntent ───────┼─► AppRouter
└───────────────┬──────────────────────────────────────────────┘   │ LogExpenseIntent ─┐     │
                │ calls                                             └───────────────────┼─────┘
┌───────────────▼─────────── Services ─────────────────────────┐                       │
│ ExpenseRepository  ◄──────────────────────────────────────────┼───────────────────────┘
│ PersistenceController.shared (ModelContainer)                │
└───────────────┬──────────────────────────────────────────────┘
┌───────────────▼──────────── Models ──────────────────────────┐
│ Expense (@Model)   ExpenseCategory (enum)                    │
└──────────────────────────────────────────────────────────────┘
```

## 2. Dependency wiring

`ExpenseTrackerApp.init()` builds the object graph once:

```
PersistenceController.shared.mainContext
        └─► ExpenseRepository
                ├─► DashboardViewModel   (held in @State by the App)
                └─► AddExpenseViewModel  (created per sheet presentation)
```

App Intents can't receive injected dependencies from a view hierarchy, so they reach the same `PersistenceController.shared` and `AppRouter.shared` directly. Intents declared in the app target run **inside the app process**, so they share the same container and main context.

## 3. Data flow

**Write path (in-app):**
`AddExpenseView` → `AddExpenseViewModel.save()` → `ExpenseRepository.add()` → `context.save()` → posts `.expenseStoreDidChange` → `DashboardView.onReceive` → `DashboardViewModel.load()`.

**Write path (Siri / Action Button, app not opened):**
`LogExpenseIntent.perform()` → `ExpenseRepository.add()` → same notification. If the dashboard isn't on screen, the notification is simply missed. `RootView` reloads on `scenePhase == .active`, so the next time the app opens it's up to date.

**Read path:** `DashboardViewModel.load()` makes two fetches: the current-month interval (for the total, count, and category shares) and the latest 50 expenses (for the day-grouped list). Aggregation happens in memory, because SwiftData can't sum `Decimal` in a fetch. That's fine up to tens of thousands of rows. Revisit in Phase 5 if needed.

## 4. Action Button → Add Expense (deep link)

```
Action Button press
  └─► Shortcut "Add Expense" (App Shortcut from ExpenseTrackerShortcuts)
        └─► iOS launches or foregrounds the app (openAppWhenRun = true)
              └─► AddExpenseIntent.perform()  @MainActor
                    └─► AppRouter.shared.presentAddExpense(category:, source: .appIntent)
                          └─► RootView .sheet(item: $router.addExpenseRequest)
                                └─► AddExpenseView: amount active and caret blinking on first frame
```

- **Cold start:** `perform()` may run before the first frame. It only sets router state, and the sheet is presented once `RootView` is on screen. No race.
- **Already open on the keypad:** `presentAddExpense` is a no-op, so an accidental second press never wipes a half-typed amount.
- **URL path:** `expensetracker://add?...` → `.onOpenURL` → `AppRouter.handle(url:)` → same router call.

## 5. Action Button → Quick Log (no app UI)

```
Action Button press
  └─► Shortcut "Quick Log" (LogExpenseIntent, openAppWhenRun = false)
        ├─ system prompt: "How much did you spend?"  (numeric)
        ├─ system prompt: "What was it for?"         (category list with icons)
        └─► perform(): repository.add() → month total
              └─► .result(dialog: "Logged ₹250.00 for Food.", view: ExpenseSnippetView)
```

## 6. Folder map

| Folder | Contents |
|---|---|
| `App/` | `ExpenseTrackerApp`, `RootView`, `AppRouter` |
| `Models/` | `Expense`, `ExpenseCategory` |
| `ViewModels/` | `DashboardViewModel` (+ `DaySection`, `CategoryTotal`), `AddExpenseViewModel` |
| `Views/Dashboard/` | `DashboardView`, `MonthSummaryCard`, `ExpenseRowView` |
| `Views/AddExpense/` | `AddExpenseView`, `AmountDisplayView`, `KeypadView`, `CategoryPickerView` |
| `Views/Components/` | `CategoryIcon`, `ExpenseCategory+Style` |
| `Services/` | `PersistenceController`, `ExpenseRepository` |
| `Intents/` | `AddExpenseIntent`, `LogExpenseIntent`, `ExpenseCategory+AppEnum`, `ExpenseTrackerShortcuts`, `ExpenseSnippetView` |
| `Utilities/` | `AmountInput` (+ `KeypadKey`), `Formatters`, `Calendar+Month`, `Haptics` |
| `PreviewSupport/` | `PreviewData` (DEBUG) |
| `Resources/` | `Info.plist`, `PrivacyInfo.xcprivacy`, `Assets.xcassets` |

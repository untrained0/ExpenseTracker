# Rules

These rules are binding. If a rule blocks a good idea, change the rule here first and give the reason. Don't quietly break it.

## 1. Architecture (MVVM)

1. **Layers:** `Views → ViewModels → Services (Repository) → Models`. Dependencies only point downward.
2. **Views** render state and forward user actions. No business logic, no `ModelContext` calls, no `@Query`. Formatting helpers (`currencyFormatted()`) are fine.
3. **ViewModels** are `@MainActor @Observable final class`. They own screen state and call the repository. They never import SwiftUI except where a SwiftUI type is part of the state, and they never hold a `View`.
4. **Repository** (`ExpenseRepository`) is the **only** type that touches `ModelContext`. Every write goes through it so the change notification always fires.
5. **Models** hold data and have no dependencies on UI frameworks. Presentation-only extensions (colors) live in `Views/Components/`.
6. **Dependency injection by initializer.** No service locators. The only singletons allowed are `PersistenceController.shared` and `AppRouter.shared`, and they exist because App Intents have no view hierarchy to inject through.
7. Pure logic (like `AmountInput`) goes into value types in `Utilities/` so it can be unit tested without SwiftData.

## 2. SwiftData

1. **Keep models CloudKit-compatible** so iCloud sync (Phase 5) needs no migration:
   - every stored property has a default value or is optional
   - no `@Attribute(.unique)`
   - relationships (if any are added) are optional
2. **Enums are stored as raw `String`** (`categoryRawValue`) and exposed through a computed property. Never rename a raw value. Add new cases instead.
3. **Money is `Decimal`**, never `Double`. Values coming from App Intents as `Double` must be rounded with `rounded(scale: 2)`.
4. Only filter on stored properties in `#Predicate`, never on computed ones.
5. Schema changes after the first release require a `VersionedSchema` + `SchemaMigrationPlan`. Record them in MEMORY.md.
6. Tests and previews use `PersistenceController.makeContainer(inMemory: true)`.

## 3. Concurrency

1. The project uses Swift 5 language mode with **`SWIFT_STRICT_CONCURRENCY = complete`**. Treat concurrency warnings as errors.
2. Everything that touches `ModelContext`, `AppRouter`, or view models runs on `@MainActor`.
3. `AppIntent.perform()` is marked `@MainActor`.
4. Don't pass `@Model` objects across actors. Pass values (`amount`, `category`) or `PersistentIdentifier`.

## 4. App Intents

1. Intent metadata (`title`, `description`, `caseDisplayRepresentations`, shortcut phrases) must be **compile-time literals**. The App Intents metadata extractor can't evaluate function calls or references to other properties. That's why SF Symbol names are repeated in `ExpenseCategory+AppEnum.swift`.
2. Every App Shortcut phrase must contain `\(.applicationName)`.
3. Intents that open the app **only change `AppRouter` state**. They never build views or navigate directly.
4. Intents that don't open the app must finish quickly (< ~5 s), must not depend on UI state, and must return a dialog so Siri and the Action Button give audible or visible confirmation.
5. Snippet views take plain values, not `@Model` objects or environment dependencies.
6. When renaming an intent type, keep the old one around (hidden with `isDiscoverable = false`) for a release, because users' Shortcuts reference it by type name.

## 5. UI

1. Follow [DESIGN.md](DESIGN.md) tokens. Don't hard-code colors. Use `ExpenseCategory.tint`, semantic colors, and the `AccentColor` asset.
2. Primary actions sit in the bottom 40% of the screen (thumb zone on the 6.9" Pro Max).
3. Minimum tap target is 44×44 pt. Keypad keys are at least 56 pt tall.
4. Every interactive element needs an accessibility label. Custom composites use `.accessibilityElement(children: .combine)` or give an explicit label and value.
5. Use `.sensoryFeedback` for haptics. The one exception is `Haptics.success()` on save-and-dismiss, where the view disappears before a trigger-based modifier would fire.
6. Numbers that change get `.monospacedDigit()` and `.contentTransition(.numericText())`.
7. No text is truncated at default Dynamic Type sizes on the smallest supported device (iPhone SE 3rd gen, 375×667 pt).

## 6. Code style

1. Swift API Design Guidelines. Types are `UpperCamelCase`, members are `lowerCamelCase`.
2. One primary type per file, and the file name matches the type (`ExpenseCategory+AppEnum.swift` for extensions).
3. `final class` by default. Prefer `struct` and `enum`.
4. `private` by default. Widen access only when needed.
5. Comments explain **why**, not what. Doc comments (`///`) go on non-obvious public API.
6. No force unwraps, except `fatalError` when the persistent store can't be created (the app can't run without it).
7. No third-party dependencies without a written reason in MEMORY.md.

## 7. Testing

1. Swift Testing (`import Testing`, `@Test`, `#expect`) for all new tests.
2. Every ViewModel and every pure utility gets tests. Views are checked by `#Preview` and on-device runs.
3. Tests inject `calendar` and `now` so they don't depend on the current date.

## 8. Process

1. Work phase by phase ([PHASES.md](PHASES.md)).
2. After each change: update [MEMORY.md](MEMORY.md) (what, where, why, what's unverified) and tick [PHASES.md](PHASES.md).
3. Put new decisions in MEMORY.md → *Decisions log* with the date.

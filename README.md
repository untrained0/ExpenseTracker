# Expense Tracker (iOS)

A fast, private, offline-first expense tracker for iPhone, built with **SwiftUI + SwiftData**. It is designed around the **Action Button**: press it, type the amount, tap Save. That takes about two seconds.

iOS doesn't let apps read SMS, notifications, or other apps' data (UPI and banking apps included), so this app makes manual entry as quick as possible instead of trying to import transactions automatically.

## Highlights

| Feature | How |
|---|---|
| Monthly dashboard | Month total, category breakdown bar, recent transactions grouped by day |
| Keypad-first entry | Custom large keypad. The amount field is active the moment the sheet opens |
| Action Button → keypad | `AddExpenseIntent` opens the app straight to the keypad |
| Action Button → no app | `LogExpenseIntent` asks for the amount and category through the system UI, saves, and shows a result snippet |
| Siri / Spotlight | App Shortcuts: "Log food expense in Expense Tracker" |
| Deep links | `expensetracker://add?category=food&amount=250` |
| Local only | SwiftData on-device store. No accounts, no network |

## Requirements

- A Mac with **Xcode 26** or later (iOS 26 SDK). Deployment target is **iOS 18.0**.
- The Action Button is on iPhone 15 Pro/Pro Max and on the iPhone 16 and 17 lines. Other devices can use Back Tap, Siri, or Control Center instead.

## Quick start

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open ExpenseTracker.xcodeproj
```

Choose your team under *Signing & Capabilities*, then run on a device.

**No Mac?** Run `swift test` on Windows for the logic tests, and push to GitHub so `.github/workflows/ios.yml` builds the full app, runs all tests on an iPhone Simulator, and uploads screenshots. See [docs/SETUP.md §6](docs/SETUP.md#6-testing-from-windows). For manual Xcode setup and the Action Button configuration, see [docs/SETUP.md](docs/SETUP.md).

## Documentation

| File | Purpose |
|---|---|
| [docs/MEMORY.md](docs/MEMORY.md) | **Start here.** What has been implemented, key decisions, known gaps |
| [docs/PHASES.md](docs/PHASES.md) | Phased roadmap with acceptance criteria |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Layers, data flow, how the Action Button intent reaches the UI |
| [docs/DESIGN.md](docs/DESIGN.md) | Visual design system, screen specs, motion, haptics, accessibility |
| [docs/RULES.md](docs/RULES.md) | Coding and architecture rules every change must follow |
| [docs/SETUP.md](docs/SETUP.md) | Project generation, Info.plist, Action Button and Shortcuts setup |

## Project layout

```
ExpenseTracker/
├── App/              App entry point, root view, router (deep links)
├── Models/           SwiftData @Model + domain enums
├── ViewModels/       @Observable view models (MVVM)
├── Views/            SwiftUI screens and components
├── Services/         Persistence container + repository
├── Intents/          App Intents, App Shortcuts, Siri snippet
├── Utilities/        Keypad input logic, formatters, haptics
├── PreviewSupport/   Sample data for #Preview (DEBUG only)
└── Resources/        Info.plist, privacy manifest, assets
ExpenseTrackerTests/  Swift Testing unit tests
project.yml           XcodeGen spec
```

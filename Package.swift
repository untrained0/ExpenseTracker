// swift-tools-version: 6.0
//
// Logic-only package, so the platform-independent code can be built and tested on
// **Windows or Linux** with `swift test`. It compiles a subset of the app's files in place
// (nothing is copied). SwiftUI, SwiftData, App Intents, and UIKit only exist on Apple
// platforms, so those files are left out. The full app is built and tested by the
// Xcode project on macOS (locally or in .github/workflows/ios.yml).
//
// When you add a new platform-independent file (e.g. more Utilities), list it in
// `sources` below so it is covered on Windows too. See docs/SETUP.md §7.
import PackageDescription

let package = Package(
    name: "ExpenseTrackerLogic",
    platforms: [.macOS(.v15), .iOS(.v18)],
    targets: [
        // Named "ExpenseTracker" so the test files' `@testable import ExpenseTracker` works unchanged.
        .target(
            name: "ExpenseTracker",
            path: "ExpenseTracker",
            exclude: [
                "Resources",
                "Views",
                "ViewModels",
                "Services",
                "Intents",
                "PreviewSupport",
                "App/ExpenseTrackerApp.swift",
                "App/RootView.swift",
                "Models/Expense.swift",
                "Utilities/Haptics.swift",
            ],
            sources: [
                "App/AppRouter.swift",
                "Models/ExpenseCategory.swift",
                "Utilities/AmountInput.swift",
                "Utilities/Calendar+Month.swift",
                "Utilities/Formatters.swift",
            ]
        ),
        .testTarget(
            name: "ExpenseTrackerLogicTests",
            dependencies: ["ExpenseTracker"],
            path: "ExpenseTrackerTests",
            exclude: ["ExpenseStoreTests.swift"],  // needs SwiftData (Apple-only)
            sources: [
                "AmountInputTests.swift",
                "AppRouterTests.swift",
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)

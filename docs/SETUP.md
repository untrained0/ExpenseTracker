# Setup

## 1. Requirements

- macOS with **Xcode 26+** (iOS 26 SDK). The deployment target is iOS 18.0.
- An Apple ID signed into Xcode. A free personal team is enough for on-device testing.
- An iPhone with an Action Button (15 Pro/Pro Max, or the 16 or 17 series) to test the hardware flow.

## 2. Generate the Xcode project

### Option A: XcodeGen (recommended)

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open ExpenseTracker.xcodeproj
```

Then open the **ExpenseTracker** target → *Signing & Capabilities* and pick your Team. If the bundle ID is taken, change `com.yourname.expensetracker` in `project.yml` and regenerate.

### Option B: Manual Xcode project

1. Xcode → File → New → Project → iOS **App**. Product Name `ExpenseTracker`, Interface **SwiftUI**, Storage **None** (we provide our own container), Testing System **Swift Testing**.
2. Delete the generated `ContentView.swift` and `ExpenseTrackerApp.swift`.
3. Drag the `ExpenseTracker/` folder from this repo into the project (Create groups, add to the app target). Drag `ExpenseTrackerTests/` into the test target.
4. Target → Build Settings:
   - `iOS Deployment Target` = 18.0
   - `Info.plist File` = `ExpenseTracker/Resources/Info.plist`, and `Generate Info.plist File` = **No**
   - `Strict Concurrency Checking` = Complete
5. Make sure `Info.plist` is **not** in *Copy Bundle Resources*, or the build fails with "multiple commands produce Info.plist".

## 3. Info.plist: what matters and why

App Intents need **no** Info.plist keys, **no** Siri capability, and **no** entitlements. Xcode extracts intent metadata at build time (the *Extract App Intents Metadata* build phase runs automatically). The only custom key is the URL scheme used for deep links:

```xml
<!-- Lets Shortcuts, widgets, Safari, etc. open expensetracker://add?category=food&amount=250
     AppRouter.handle(url:) parses it and opens the Add Expense sheet. -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>expensetracker</string>
        </array>
    </dict>
</array>
```

`PrivacyInfo.xcprivacy` declares the `UserDefaults` usage (reason `CA92.1`, used to remember the last category), which App Store submission requires.

## 4. Configure the Action Button

1. Build and run the app on your iPhone **once**. iOS registers App Shortcuts at install or first launch.
2. Open **Settings → Action Button**.
3. Swipe to **Shortcut**, then tap **Choose a Shortcut**.
4. Scroll to the **Expense Tracker** app section and pick one of:
   - **Add Expense**: opens the app on the keypad with the amount active. *(Recommended.)*
   - **Quick Log**: logs the expense through the system prompts without opening the app.
5. Press the Action Button.

You don't need to build anything in the Shortcuts app. `ExpenseTrackerShortcuts` (an `AppShortcutsProvider`) publishes these automatically.

### Optional: custom Shortcut (e.g. always "Food")

1. Shortcuts app → **+** → Add Action → search "Expense Tracker".
2. Pick **Add Expense** and set *Category* to Food, or pick **Log Expense** and fill in the fields.
3. Save it, then choose that shortcut under Settings → Action Button → Shortcut.

### Optional: Siri

- "Add an expense in Expense Tracker"
- "Log food expense in Expense Tracker" (asks for the amount only)

## 5. Testing without the Action Button

- **Shortcuts app:** run the *Add Expense* or *Quick Log* App Shortcut directly.
- **Simulator deep link:**

```bash
xcrun simctl openurl booted "expensetracker://add?category=food&amount=250"
```

- **Unit tests:** ⌘U in Xcode.

## 6. Testing from Windows

The UI (SwiftUI), storage (SwiftData), and App Intents only exist on Apple platforms, so testing is split in two:

| What | Where | Command | Covers |
|---|---|---|---|
| Logic tests | Your Windows PC | `swift test` | `AmountInput`, formatters, month math, `ExpenseCategory`, `AppRouter` deep links (17 tests) |
| Full build + all tests + screenshots | GitHub-hosted Mac (`.github/workflows/ios.yml`) | `git push` | Compiles the whole app, runs all 25 tests on an iPhone Simulator, captures 3 screenshots |

### 6.1 Logic tests on Windows

One-time install. Visual Studio Build Tools 2022 (C++ tools + Windows SDK) is a prerequisite and is already on the main dev PC:

```powershell
winget install --id Swift.Toolchain -e
```

Open a **new** terminal (so `swift` is on PATH), then from the repo root:

```powershell
swift test
```

`Package.swift` compiles only the platform-independent files, in place. **When you add a new file that doesn't depend on Apple frameworks, add it to `sources` in `Package.swift`** so it's tested on Windows too.

### 6.2 Full build on GitHub Actions

1. Create an empty repo on github.com (no README), then:

```powershell
git remote add origin https://github.com/<you>/<repo>.git
```

```powershell
git push -u origin main
```

2. Open the repo's **Actions** tab. Each push runs *iOS CI*. You can also start it by hand with **Run workflow**.
3. When it finishes, scroll to **Artifacts**:
   - `screenshots`: dashboard, Add Expense (opened through the Action Button's code path via deep link), and dark mode
   - `test-results`: `xcodebuild.log` and `TestResults.xcresult`
4. Compile errors show up as inline annotations on the commit.

Runner: `macos-26` (Xcode 26). If GitHub renames or retires that image, update `runs-on` in the workflow.

## 7. Troubleshooting

| Symptom | Fix |
|---|---|
| App doesn't appear under Action Button → Shortcut | Launch the app once, then wait about 30 s or restart the phone. Check that the *Extract App Intents Metadata* build phase ran (build log). |
| Old intent names or phrases stick around | Delete the app, reinstall, and restart the device. Siri caches phrases. |
| Build error: "Info.plist … copy bundle resources" | Remove `Info.plist` from *Copy Bundle Resources*. |
| App Intents metadata error about non-constant values | Intent titles, descriptions, and `caseDisplayRepresentations` must be literals (RULES.md §4.1). |
| Quick Log saved, but the dashboard didn't update | It reloads when the app becomes active. Pull to refresh as a fallback. |
| Windows: `swift` not recognized | Open a new terminal after installing. The installer updates PATH only for new sessions. |
| Windows: linker or `ucrt` / `vcruntime` errors | Visual Studio Build Tools needs the *MSVC x64* and *Windows SDK* components. Re-run the VS Installer and add them. |
| CI: "No iPhone simulator found" | The runner image changed. Check `xcrun simctl list` in the log and adjust the jq filter. |

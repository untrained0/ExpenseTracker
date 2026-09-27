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

Then open the **ExpenseTracker** target → *Signing & Capabilities* and pick your Team. If the bundle ID is taken, change `com.untrained0.expensetracker` in `project.yml` (and `BUNDLE_ID` in the workflow) and regenerate.

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

Then from the repo root, in any PowerShell window:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-windows.ps1
```

The script loads the Visual Studio developer environment, because Swift on Windows needs MSVC's `link.exe`. It also reloads `PATH` and `SDKROOT`, so it works even in a terminal opened before Swift was installed. Running plain `swift test` fails with *"could not find CLI tool `link`"* or *"unable to load standard library"* unless you're in a *Developer PowerShell for VS 2022* opened after the install.

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

## 7. Install on your iPhone from Windows (sideloading)

CI's **Build unsigned IPA** job produces `ExpenseTracker.ipa` on every push. A sideloading tool on Windows re-signs it with your Apple ID and installs it over USB. No Mac is needed.

### One-time setup (PC)
1. Install **Sideloadly** from its official site, https://sideloadly.io. Follow its Windows prerequisites for Apple's USB drivers. It asks for the iTunes and iCloud installers from Apple's website, **not** the Microsoft Store versions.
2. Connect the iPhone by USB. Unlock it and tap **Trust This Computer**.

### Every install
1. GitHub → **Actions** → latest green *iOS CI* run → **Artifacts** → `ExpenseTracker-ipa`. It downloads as a `.zip`, so extract `ExpenseTracker.ipa` from it.
2. Open Sideloadly, drag in `ExpenseTracker.ipa`, pick your iPhone and enter your Apple ID, then click **Start**. You can use a secondary Apple ID if you prefer. Sideloadly sends the login to Apple to create a free development certificate.
3. The app icon appears on the Home Screen. The icon is blank until the AppIcon artwork is added.

### First launch only (iPhone)
1. **Settings → General → VPN & Device Management** → your Apple ID → **Trust**.
2. Open the app. iOS will say **Developer Mode** is required. Go to **Settings → Privacy & Security → Developer Mode** → On → restart → confirm **Turn On**. The toggle only appears after a developer-signed app has been installed.
3. Open the app once more so iOS registers its App Shortcuts. Then set up the Action Button (§4).

### Free Apple ID limits
| Limit | What it means |
|---|---|
| Signature expires after **7 days** | The app stops launching. Re-sideload the same or a newer `.ipa`. **Your data survives** as long as you reinstall over the app instead of deleting it. |
| 3 sideloaded apps at once, 10 new app IDs per week | Only matters if you sideload other apps too |
| Data lives on the phone only | Deleting the app deletes your expenses. CSV export (Phase 5) or TestFlight (paid) fix this long-term |

### Test checklist (Phase 2 "done when")
- [ ] Action Button → *Add Expense* with the app **fully closed** (swipe it away first): keypad appears and the caret blinks with no tap
- [ ] Same with the app already open on the dashboard
- [ ] Press the Action Button again while the keypad is open: the typed amount is kept
- [ ] Action Button → *Quick Log*: amount prompt → category list → "Logged ₹… for …" card, and the app stays closed
- [ ] Open the app: the Quick Log expense is on the dashboard and the month total is updated
- [ ] Siri: "Log food expense in Expense Tracker"

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| App doesn't appear under Action Button → Shortcut | Launch the app once, then wait about 30 s or restart the phone. Check that the *Extract App Intents Metadata* build phase ran (build log). |
| Old intent names or phrases stick around | Delete the app, reinstall, and restart the device. Siri caches phrases. |
| Build error: "Info.plist … copy bundle resources" | Remove `Info.plist` from *Copy Bundle Resources*. |
| App Intents metadata error about non-constant values | Intent titles, descriptions, and `caseDisplayRepresentations` must be literals (RULES.md §4.1). |
| Quick Log saved, but the dashboard didn't update | It reloads when the app becomes active. Pull to refresh as a fallback. |
| Windows: `swift` not recognized | Open a new terminal after installing. The installer updates PATH only for new sessions. |
| Windows: linker or `ucrt` / `vcruntime` errors | Visual Studio Build Tools needs the *MSVC x64* and *Windows SDK* components. Re-run the VS Installer and add them. |
| Sideloadly: device not detected | Install the Apple website versions of iTunes and iCloud (not the Microsoft Store ones), replug the cable, and unlock the phone |
| Sideloadly: "App ID not available" | Someone else registered the bundle ID. Use Sideloadly's *Advanced → Change bundle ID*, or change it in `project.yml` |
| App opens then closes immediately | The 7-day signature expired, or Developer Mode is off. Re-sideload, or check §7 "First launch" |
| Expense Tracker missing from the Action Button list | Open the app once after installing, wait ~30 s, and restart the phone if needed. CI fails the build if `Metadata.appintents` is missing, so the metadata is there |
| CI: "No iPhone simulator found" | The runner image changed. Check `xcrun simctl list` in the log and adjust the jq filter. |

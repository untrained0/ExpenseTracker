# CLAUDE.md

Guidance for AI assistants working in this repo.

1. Read [docs/MEMORY.md](docs/MEMORY.md) first. It records what has been built and why.
2. Follow [docs/RULES.md](docs/RULES.md). It is binding for all code changes.
3. Check [docs/PHASES.md](docs/PHASES.md) to see which phase is active. Don't start the next phase's work unasked.
4. After finishing any change, update `docs/MEMORY.md` (the implementation log) and tick the boxes in `docs/PHASES.md`.
5. The primary dev machine is **Windows**. There, `swift test` builds and tests only the platform-independent logic (see `Package.swift`). The full app (SwiftUI, SwiftData, App Intents) is verified only by the GitHub Actions macOS workflow or by Xcode on a Mac. Don't claim a UI or intent change was build-verified otherwise, and record anything unverified under "Known gaps" in MEMORY.md.

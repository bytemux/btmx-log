# iOS development tools

One tool per job. Alternatives we looked at and do not use are listed at the end.

✅ = present on this Mac (checked 2026-11-23), either seen directly (command output or
/Applications) or shipped inside Xcode 27.2. It does not mean the project uses it yet.

## Build and run
- ✅ **Xcode 27.2** — Apple's IDE; includes iOS SDK, Swift compiler, Simulator, Instruments.
- ✅ **xcodebuild** — command-line build and test; this is how Claude Code builds and tests.
- ✅ **xcrun simctl** — command-line simulator control: boot, install, launch, screenshot.
- ✅ **iOS Simulator (iOS 27.2)** — runs the app on the Mac, no iPhone needed.
- ✅ **Swift Package Manager** — dependencies, built into Xcode.

## Unit tests
- ✅ **Swift Testing** — Apple's current unit test framework (`@Test`, `#expect`).

## UI tests
- ✅ **XCUITest** — Apple's UI test framework; taps by id or by coordinates, takes screenshots.

## Code formatting
- ✅ **swift-format** — Apple's formatter, bundled with Xcode as `swift format`.

## Debugging and profiling
- ✅ **LLDB** — debugger, in Xcode and on the command line.
- ✅ **Instruments** — profiling: CPU, memory, leaks, SwiftUI updates.
- ✅ **`log stream` / Console.app** — read app logs from the simulator.

## Design
- ✅ **SF Symbols** — Apple's icon library and browser app.

## Distribution (later, needs paid developer account)
- **App Store Connect** — web portal for builds, testers and store listing.
- ✅ **TestFlight** — installs beta builds on a real iPhone.

## Considered, not used
- **Maestro** — YAML UI flows; simpler to write, but simulator only, black-box, needs Java; XCUITest covers it.
- **Appium** — cross-platform WebDriver that runs XCUITest underneath; only useful if we add Android.
- **XCTest (unit tests)** — older unit test style; replaced by Swift Testing (XCUITest still uses XCTest).
- **XcodeBuildMCP** — MCP wrapper over xcodebuild/simctl; Claude Code can call those CLIs directly.
- **Xcode MCP (`xcrun mcpbridge`)** — needs Xcode open with the project; not needed for a CLI workflow.
- **XcodeGen / Tuist** — project generators; not needed while the project is this small.
- **SwiftLint** — linter; swift-format is enough for now.
- **fastlane** — release automation; not needed before the first App Store release.

# Technology Stack

**Analysis Date:** 2026-04-05

## Languages

**Primary:**
- Swift 5.0 - All application code: models, views, view models, services, utilities

**Secondary:**
- XML - `Info.plist` configuration (remote-notification background mode only)
- Ruby / YAML - Not used; no fastlane active configuration despite `.gitignore` entry

## Runtime

**Environment:**
- iOS 18.5+ (minimum deployment target: `IPHONEOS_DEPLOYMENT_TARGET = 18.5`)
- Apple platforms only (iOS simulator and device)
- SwiftUI lifecycle app (`@main` App protocol)

**Package Manager:**
- Swift Package Manager (SPM) - configured in Xcode project but **zero external packages** currently installed
- No CocoaPods, Carthage, or Accio dependencies
- No `Package.swift` file (Xcode-managed SPM only)

## Frameworks

**Core (Apple SDK):**
- SwiftUI - All UI views and layout; app entry point uses `Scene`/`WindowGroup` pattern
- Combine - Reactive bindings in ViewModels (`@Published`, `NotificationCenter.default.publisher`, `sink`, `AnyCancellable`)
- Foundation - Data models, formatting, date calculations, `NotificationCenter`

**Testing:**
- XCTest - Unit test framework (`ExpenseTrackerAppTests/ExpenseTrackerAppTests.swift`)
- XCUITest - UI test framework (`ExpenseTrackerAppUITests/`)

**Build/Dev:**
- Xcode 16+ (project format is `.xcodeproj`, no `.xcworkspace`)
- `xcodebuild` CLI for CI builds: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'`

## Key Dependencies

**Critical:**
- None. This is a zero-dependency app. All functionality is built on Apple first-party frameworks only.

**Infrastructure:**
- `@AppStorage` - UserDefaults wrapper for persistent settings (currency, theme); see `SettingsViewModel.swift`
- `NotificationCenter` - Internal event bus for transaction CRUD notifications; see `Constants.swift`

## Configuration

**Environment:**
- No `.env` files present
- `Info.plist` contains only `UIBackgroundModes` with `remote-notification` (currently unused)
- No `GoogleService-Info.plist` (Firebase not integrated)
- All configuration is code-based in `Constants.swift` and `DataService.swift`

**Build:**
- Build config in `ExpenseTrackerApp.xcodeproj/project.pbxproj`
- Swift version: 5.0 (all targets)
- iOS deployment target: 18.5 (all targets)
- Three build targets:
  1. `ExpenseTrackerApp.app` (main app)
  2. `ExpenseTrackerAppTests.xctest` (unit tests)
  3. `ExpenseTrackerAppUITests.xctest` (UI tests)

## Platform Requirements

**Development:**
- macOS with Xcode 16+
- iOS 18.5 Simulator (iPhone 16 is the development target device)
- No external tooling required

**Production:**
- iPhone / iPad running iOS 18.5+
- Not configured for App Store distribution yet (no archive/scheme settings for release)
- No CI/CD pipeline configured

## Data Persistence

**Current State:**
- In-memory only. `DataService` is a singleton with `@Published` arrays
- All data lost on app termination
- `@AppStorage` persists only theme and currency preference strings to UserDefaults
- Models conform to `Codable` but no encode/decode calls exist yet

**Implication:**
- Ready for future persistence (Core Data, SwiftData, or file-based) since all models are `Codable`
- `DataService.shared` singleton pattern makes it a single point to add persistence

## Key Architecture Decisions

- **MVVM pattern**: `@MainActor ObservableObject` ViewModels with `@Published` properties
- **No external dependencies**: Entirely Apple frameworks
- **SwiftUI only**: No UIKit/Storyboard usage
- **Reactive updates**: Combine-based `NotificationCenter` subscriptions in ViewModels
- **Singleton data layer**: `DataService.shared` accessed by all ViewModels
- **Swift previews**: `#Preview` macros used in views for Xcode Canvas previews

---

*Stack analysis: 2026-04-05*

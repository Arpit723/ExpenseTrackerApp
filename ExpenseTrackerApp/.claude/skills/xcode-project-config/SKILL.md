---
name: xcode-project-config
description: Manage Xcode project configuration including build settings, SPM dependencies, scheme setup, Info.plist, and target configuration for SwiftUI iOS apps. Use when adding packages, changing deployment targets, configuring build phases, or managing .xcodeproj settings.
---

# Xcode Project Config Skill

## Operating Rules

- Prefer `xcodebuild` CLI commands over manual Xcode GUI changes when possible
- Always verify changes compile: `xcodebuild build -scheme ... -destination '...'`
- Never directly edit `project.pbxproj` unless absolutely necessary — use `xcodebuild` or Xcode
- When modifying `project.pbxproj`, always back up first and verify the build after
- Use Swift Package Manager (SPM) for all dependencies — no CocoaPods or Carthage
- Keep `Info.plist` minimal — prefer build settings in the target for most configuration

## Task Workflow

### Add an SPM dependency

1. **Determine the package URL and version rule**:
   - Example: Firebase SDK `https://github.com/firebase/firebase-ios-sdk.git` from `11.0.0` to `< 12.0.0`
2. **Add via Xcode** (recommended for safety):
   - File > Add Package Dependencies > enter URL > select version > select products
   - Or guide the user through this step
3. **Verify the package resolves**:
   ```bash
   xcodebuild -resolvePackageDependencies \
     -scheme ExpenseTrackerApp \
     -clonedSourcePackagesDirPath .build
   ```
4. **Verify build succeeds**:
   ```bash
   xcodebuild build -scheme ExpenseTrackerApp \
     -destination 'platform=iOS Simulator,name=iPhone 16'
   ```
5. **Commit** `project.pbxproj` and `Package.resolved` (if version-locked)

### Change deployment target

1. **Update in project settings** (affects all targets):
   - In Xcode: Project > Info > iOS Deployment Target
   - Or set `IPHONEOS_DEPLOYMENT_TARGET` in build settings
2. **Verify all targets match**:
   ```bash
   grep -r "IPHONEOS_DEPLOYMENT_TARGET" ExpenseTrackerApp.xcodeproj/project.pbxproj
   ```
3. **Update `CLAUDE.md`** to reflect the new minimum deployment target
4. **Build and test** to verify no API availability issues

### Add a new file to the project

1. **Create the Swift file** in the correct directory
2. **Add to Xcode target** (the file must be in the build phase's "Compile Sources"):
   - In Xcode: File > Add Files to "ExpenseTrackerApp"
   - Or verify with `xcodebuild` that it's included
3. **Verify build** includes the new file
4. **Follow project naming conventions** (see `CLAUDE.md`)

### Configure build settings

Common build settings for this project:

| Setting | Value | Purpose |
|---------|-------|---------|
| `SWIFT_VERSION` | `5.0` | Swift language version |
| `IPHONEOS_DEPLOYMENT_TARGET` | `18.5` | Minimum iOS version |
| `TARGETED_DEVICE_FAMILY` | `1` | iPhone only (1=iPhone, 2=iPad, "1,2"=Universal) |
| `SWIFT_OPTIMIZATION_LEVEL` | `-Onone` (Debug) / `-O` (Release) | Optimization |
| `INFOPLIST_FILE` | `ExpenseTrackerApp/Info.plist` | Path to Info.plist |
| `PRODUCT_BUNDLE_IDENTIFIER` | Set per target | App bundle ID |
| `CODE_SIGN_IDENTITY` | `-` (Simulator) / `Apple Development` (Device) | Signing |

### Configure Info.plist

Keep `Info.plist` minimal. Common entries:

| Key | Purpose |
|-----|---------|
| `UIBackgroundModes` | `remote-notification` (for push notifications) |
| `NSAppTransportSecurity` | Allow specific network domains (if needed) |
| `CFBundleDisplayName` | App name shown on home screen |
| `UIApplicationSceneManifest` | Scene configuration (auto-managed by SwiftUI) |

### Add a new build target (test target)

1. **In Xcode**: File > New > Target > Unit Testing Bundle
2. **Configure**:
   - Target name: `ExpenseTrackerAppTests`
   - Target to test: `ExpenseTrackerApp`
   - Language: Swift
3. **Verify test discovery**:
   ```bash
   xcodebuild test -scheme ExpenseTrackerApp \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     -only-testing:ExpenseTrackerAppTests
   ```

## Build Commands Reference

```bash
# Build
xcodebuild build \
  -scheme ExpenseTrackerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Clean build
xcodebuild clean build \
  -scheme ExpenseTrackerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Run tests
xcodebuild test \
  -scheme ExpenseTrackerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'

# Resolve packages
xcodebuild -resolvePackageDependencies \
  -scheme ExpenseTrackerApp

# List schemes
xcodebuild -list

# Show build settings
xcodebuild -scheme ExpenseTrackerApp -showBuildSettings

# Archive for release
xcodebuild archive \
  -scheme ExpenseTrackerApp \
  -archivePath build/ExpenseTrackerApp.xcarchive
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No such module 'FirebaseCore'" | Package not resolved — run `-resolvePackageDependencies` |
| "Linker error: symbol not found" | Framework not linked to target — check "Link Binary with Libraries" build phase |
| "Build fails after SPM add" | Clean build folder (Cmd+Shift+K) and rebuild |
| "Duplicate symbols" | Same file added to multiple targets — remove from wrong target |
| "Stored properties cannot be marked `@MainActor`" | Update Xcode / check Swift version setting |
| "Package resolution timeout" | Check network, try ` -clonedSourcePackagesDirPath` to local cache |

## Configuration Checklist

After any project configuration change:

- [ ] Build succeeds with `xcodebuild build`
- [ ] Tests pass with `xcodebuild test`
- [ ] All targets have consistent deployment target
- [ ] `project.pbxproj` committed (not just local changes)
- [ ] `CLAUDE.md` updated if deployment target or dependencies changed
- [ ] No stale build artifacts (clean build succeeds)

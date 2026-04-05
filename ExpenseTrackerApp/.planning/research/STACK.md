# Stack Research

**Domain:** Firebase Auth + Firestore on iOS (Swift/SwiftUI)
**Researched:** 2026-04-05
**Confidence:** HIGH (official Firebase documentation, verified GitHub releases, official setup guides)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Firebase Apple SDK (firebase-ios-sdk) | 12.9.0 | Auth + Firestore via SPM | Latest stable release (Feb 3, 2026). Mature SDK with full Swift async/await support, Codable integration, and SwiftUI-friendly patterns. Managed service eliminates backend work. |
| FirebaseAuth | 12.9.0 (module) | Email/password authentication | Part of Firebase Apple SDK. Handles user registration, login, session persistence (iOS keychain), and auth state listening. Supports callback and async/await APIs. No custom token management needed. |
| FirebaseFirestore | 12.9.0 (module) | Per-user persistent data storage | Part of Firebase Apple SDK. NoSQL document database with automatic offline persistence, Codable support, and subcollection-based data scoping. Subcollections at `users/{uid}/transactions` provide natural per-user isolation. |
| FirebaseFirestoreSwift | 12.9.0 (module) | Codable support for Firestore | Enables `document.data(as: MyCodableStruct.self)` and `try Firestore.Encoder().encode(myStruct)`. Existing `Transaction`, `Category`, `UserProfile` models already conform to `Codable` -- this module gives zero-boilerplate Firestore mapping. |
| FirebaseCore | 12.9.0 (module) | SDK initialization | Required for `FirebaseApp.configure()`. Called once in `AppDelegate` or `App.init()`. |
| XCTest | Built-in (Xcode) | Unit testing framework | Apple's native testing framework. No external dependency. Supports protocol-based mocking, `XCTestExpectation` for async tests, and code coverage reporting. |
| Swift Package Manager | Built-in (Xcode) | Dependency management | Xcode-native. No extra tooling. Firebase SDK officially supports SPM as the primary installation method since 2023. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| FirebaseFirestore (Encoders/Decoders) | 12.9.0 (built-in) | `Firestore.Encoder()` / `Firestore.Decoder()` for Codable mapping | Every Firestore read/write operation. Use `try Firestore.Encoder().encode(transaction)` instead of manual dictionary construction. Handles `Date` to `Timestamp` conversion automatically. |
| FirebaseAuth `Auth.auth().addStateDidChangeListener` | 12.9.0 (built-in) | Reactive auth state observation | In `AuthViewModel.init()`. Stores `User?` in `@Published` property. Replaces synchronous `currentUser` checks. Must be used -- never read `Auth.auth().currentUser` directly for UI routing. |
| SwiftUI `@UIApplicationDelegateAdaptor` | iOS 14+ (built-in) | Firebase initialization in SwiftUI lifecycle | In `ExpenseTrackerAppApp.swift`. Add an `AppDelegate` class that calls `FirebaseApp.configure()` in `init()`. Wire via `@UIApplicationDelegateAdaptor(AppDelegate.self) var delegate`. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Xcode Code Coverage | Measure 80% coverage target on ViewModels/Services | Enable via Edit Scheme > Test > Options > Code Coverage. Focus coverage on ViewModels and Services, not Views. |
| Firebase Console | Create project, configure Auth, set Firestore rules, manage users | Create one Firebase project for development. Enable Email/Password sign-in method in Authentication settings. Create Firestore database in test mode initially, then deploy restrictive rules. |
| GoogleService-Info.plist | Firebase SDK configuration file | Download from Firebase Console > Project Settings. Add to Xcode project target. MUST add to `.gitignore` to avoid exposing project configuration in the repository. |
| Firebase Emulator Suite (optional) | Local Firestore + Auth testing without network | Advanced usage. Not required for this milestone but available via `firebase-tools` npm package if local testing becomes important. |

## Installation

### 1. Add Firebase SDK via Swift Package Manager

In Xcode:
1. File > Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk.git`
3. Dependency Rule: "Up to Next Major Version" with base: `12.0.0`
4. Select product targets to add to `ExpenseTrackerApp`:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift` (provides Codable support, separate from `FirebaseFirestore`)
   - `FirebaseCore`

### 2. Add GoogleService-Info.plist

```bash
# Download from Firebase Console > Project Settings > Your Apps > iOS
# Add to Xcode project (drag into navigator, ensure target membership checked)

# IMPORTANT: Add to .gitignore
echo "ExpenseTrackerApp/GoogleService-Info.plist" >> .gitignore
```

### 3. Initialize Firebase in App Entry Point

```swift
// AppDelegate.swift (new file)
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

// ExpenseTrackerAppApp.swift (modify existing)
@main
struct ExpenseTrackerAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var dataService = DataService.shared
    // ...
}
```

### 4. No npm/pod/carthage commands needed

SPM handles everything. No CocoaPods installation, no Podfile, no `pod install`.

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Dependency Manager | Swift Package Manager | CocoaPods | CocoaPods still works but SPM is Firebase's officially recommended installation method as of 2024+. CocoaPods requires `pod install`, Podfile management, and a `.xcworkspace`. SPM is built into Xcode with zero extra tooling. |
| Dependency Manager | Swift Package Manager | Carthage | Firebase SDK does not officially support Carthage. Would require manual binary builds. Not viable. |
| Backend | Firebase Firestore | CloudKit | CloudKit is Apple-native but has lower query flexibility, no cross-platform support, complex CKRecord mapping, and no built-in auth. Firestore has simpler Codable integration, built-in auth pairing, and better documentation. |
| Backend | Firebase Firestore | Firebase Realtime Database | Realtime Database is the older Firebase database. It uses a single large JSON tree (not documents/collections), lacks native Codable support, has no subcollections for per-user scoping, and has less flexible querying. Firestore is the recommended database for all new Firebase projects. |
| Auth | Firebase Auth (Email/Password) | Custom backend auth | Custom auth requires building token management, session persistence, password hashing, email verification infrastructure, and CSRF protection. Firebase Auth handles all of this as a managed service. Not worth the engineering time for an indie expense tracker. |
| Auth | Firebase Auth (Email/Password) | Supabase Auth | Supabase is a strong alternative (PostgreSQL-based, open source). However, switching to Supabase means learning a different SDK, different data model (SQL vs NoSQL), and different console. Firebase has better Apple ecosystem integration and is already the project decision in PROJECT.md. |
| Testing | XCTest with protocol mocks | Quick/Nimble | Quick/Nimble adds BDD-style syntax but introduces an external dependency for marginal DX improvement. XCTest is built-in, sufficient for protocol-based mocking, and avoids dependency management overhead. The project constraint is "no external UI libraries" -- applying the same philosophy to test libraries keeps the dependency footprint minimal. |
| Testing | XCTest with protocol mocks | Mockolo / Sourcery (auto-generated mocks) | Auto-generated mocks are useful for large codebases with many protocols. For this project (2 protocols: `DataServiceProtocol`, `AuthServiceProtocol`), hand-written mocks are simpler, more readable in tests, and avoid a code generation build step. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| CocoaPods | Extra tooling, `.xcworkspace` management, Podfile conflicts, slower builds. SPM is officially recommended by Firebase for new projects. | Swift Package Manager (built into Xcode) |
| Firebase Realtime Database | Legacy product. No subcollections, no native Codable support, JSON tree model. Firestore is the recommended database for all new projects. | Firebase Firestore |
| Firebase Dynamic Links | Removed in Firebase SDK 12.0.0 (July 2025). No longer available. Not applicable. | N/A -- not needed for expense tracker |
| FirebaseUI for iOS | Pre-built auth UI library. Conflicts with custom SwiftUI design. Does not support custom registration fields (Name, Gender, Phone). Adds opaque dependency. | Custom SwiftUI auth views using the project's design language (theme colors, Constants) |
| Combine-based Firebase wrappers (e.g., `FirebaseCombineSwift`) | Unnecessary abstraction layer. Firebase SDK supports async/await natively since v10.x. The project uses `@Published` + `ObservableObject` which integrates directly with Firebase callbacks. Adding a Combine wrapper adds complexity without benefit. | Use Firebase SDK's built-in async/await APIs or callback APIs directly |
| `@AppStorage` for auth state | `@AppStorage` writes to UserDefaults, which does not reflect actual Firebase Auth session state. A user could be signed out server-side but `@AppStorage` still says authenticated. | `Auth.auth().addStateDidChangeListener` in an `ObservableObject` with `@Published var` |
| `Auth.auth().currentUser` for UI routing | `currentUser` is `nil` on first app launch until the async keychain lookup completes. Checking it once at startup causes a login screen flash for authenticated users. | `addStateDidChangeListener` which fires after session restoration completes |
| Manual dictionary construction for Firestore writes | `["field": value]` dictionaries have no compile-time safety. Typos in field names cause silent data loss. Refactoring breaks silently. | `Firestore.Encoder().encode(codableStruct)` and `Firestore.Decoder().decode(Type.self, from: document)` with Codable models |
| Open Firestore security rules (`allow read, write: if true`) | Exposes all user data to anyone. Even during development, this is dangerous if the Firebase project is not isolated. | Rules scoped to `request.auth.uid == uid` from the start. Use Firebase emulator for unrestricted local testing. |

## Stack Patterns by Variant

**If building the AuthViewModel (the primary pattern for this project):**
- Use `ObservableObject` with `@Published var authState: AuthState` (enum: `.loading`, `.authenticated`, `.unauthenticated`)
- Attach `Auth.auth().addStateDidChangeListener` in `init()`
- Store the `AuthStateDidChangeListenerHandle` as an instance property (prevents deallocation)
- Map Firebase `User` to a simple app-level `AppUser` struct (decouples from Firebase types)
- This pattern ensures no `import FirebaseAuth` leaks into ViewModels

**If building the FirestoreDataService (the primary data pattern):**
- Use one-time `getDocuments()` fetches, not `addSnapshotListener`
- The expense tracker is single-user, single-device -- real-time sync is unnecessary complexity
- Call `getDocuments()` on view load and after mutations
- Cache results in `@Published` arrays on the service
- This keeps the data flow simple: ViewModel calls service method -> service fetches from Firestore -> publishes result

**If offline support becomes important (not this milestone):**
- Firestore offline persistence is enabled by default on iOS -- no configuration needed
- Cached data is automatically served when offline
- The only requirement: call `Firestore.firestore().clearPersistence()` on sign-out to prevent cross-user cache leaks
- Do NOT design for explicit offline-first (conflict resolution, sync queues) -- default behavior is sufficient

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| firebase-ios-sdk 12.9.0 | Xcode 16.0+ | Minimum Xcode version for Firebase SDK 12.x. Xcode 16.x ships with Swift 5.x and iOS 18.x SDK. |
| firebase-ios-sdk 12.9.0 | iOS 13.0+ (deployment target) | Firebase SDK 12.x supports iOS 13+. This project targets iOS 18.5+ so no compatibility issue. |
| FirebaseAuth 12.9.0 | FirebaseFirestore 12.9.0 | All Firebase modules within the same SDK version are compatible. Always use the same version across all Firebase modules. |
| FirebaseFirestoreSwift 12.9.0 | FirebaseFirestore 12.9.0 | `FirebaseFirestoreSwift` is a companion module to `FirebaseFirestore`. Must be the same version. Provides Codable encoder/decoder extensions. |
| Firebase SDK 12.x | Swift 6 strict concurrency | Firebase SDK 12.x has improved Swift 6 conformance but some APIs may still require `@Sendable` annotations or `nonisolated(unsafe)` for strict concurrency mode. This project uses Swift 5.0 (not strict concurrency), so no issue. |
| FirebaseFirestoreSwift Codable | `Transaction` model (existing) | `Transaction` conforms to `Codable` with `UUID` and `Date` properties. Firestore automatically converts `Date` to `Timestamp`. `UUID` will be encoded as a string by default -- verify round-trip in tests. |

## Key Architecture Decisions Enabled by This Stack

### Protocol Extraction Order

The stack enables a specific build order that maximizes testability:

1. **Extract `DataServiceProtocol`** from existing `DataService` -- no Firebase needed
2. **Extract `AuthServiceProtocol`** -- defines register/login/logout/stateListener
3. **Make existing `DataService` conform to `DataServiceProtocol`** -- verify in-memory still works
4. **Write unit tests with mock services** -- test ViewModels in isolation using protocol mocks
5. **Implement `FirebaseAuthService: AuthServiceProtocol`** -- wraps FirebaseAuth
6. **Implement `FirebaseDataService: DataServiceProtocol`** -- wraps FirebaseFirestore
7. **Swap services in app entry point** -- change DI wiring, no ViewModel changes

This order means Firebase is only imported in the service implementations (`FirebaseDataService`, `FirebaseAuthService`), never in ViewModels or Views.

### SPM Product Selection

When adding the Firebase package in Xcode, select exactly these product targets:
- `FirebaseAuth` (not `FirebaseAuthCombine-Community` or any other variant)
- `FirebaseFirestore` (the main module)
- `FirebaseFirestoreSwift` (separate checkbox -- provides Codable extensions)
- `FirebaseCore` (usually auto-included as a transitive dependency)

Do NOT select:
- `FirebaseAnalytics` -- not needed for this milestone
- `FirebaseCrashlytics` -- not needed for this milestone
- `FirebaseAuthCombine-Community` -- unnecessary, use native async/await instead

## Sources

- Firebase Apple SDK GitHub Releases -- version 12.9.0 verified (https://github.com/firebase/firebase-ios-sdk/releases)
- Firebase iOS Setup Documentation -- SPM installation, SwiftUI initialization (https://firebase.google.com/docs/ios/setup)
- Firebase Auth Password Authentication Docs -- register/login/signOut APIs (https://firebase.google.com/docs/auth/ios/password-auth)
- Firebase Firestore Quickstart Docs -- CRUD operations, subcollections (https://firebase.google.com/docs/firestore/quickstart)
- Firebase SPM Installation Guide -- dependency rule configuration (https://github.com/firebase/firebase-ios-sdk/blob/main/SwiftPackageManager.md)
- Codebase analysis: `DataService.swift`, `Transaction.swift`, `Category.swift`, `UserProfile.swift`, `ExpenseTrackerAppApp.swift`

---
*Stack research for: Firebase Auth + Firestore iOS migration*
*Researched: 2026-04-05*

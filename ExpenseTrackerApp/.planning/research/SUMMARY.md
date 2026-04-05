# Project Research Summary

**Project:** ExpenseTrackerApp - Firebase Auth + Firestore Migration
**Domain:** iOS (Swift/SwiftUI) expense tracker migrating from in-memory data to Firebase backend
**Researched:** 2026-04-05
**Confidence:** HIGH

## Executive Summary

This is a straightforward Firebase Auth + Firestore migration for a single-user, single-device SwiftUI expense tracker. The existing codebase already uses MVVM with `ObservableObject` ViewModels, `Codable` models, and a centralized `DataService`. The recommended approach is a protocol-first migration: extract `DataServiceProtocol` and `AuthServiceProtocol` from the current codebase, then implement `FirebaseAuthService` and `FirestoreDataService` as conforming implementations behind those protocols. This preserves all existing behavior while enabling 80% unit test coverage via mock services and making the Firebase swap purely a wiring change in the app entry point.

The key risk is ordering. If protocol extraction is skipped and Firebase is wired directly into ViewModels, the 80% coverage target becomes impossible and the codebase accumulates hard coupling to Firebase types. Secondary risks include auth state race conditions on app launch (showing the login screen to authenticated users), registration atomicity failures (Auth user created but Firestore profile write fails), and Firestore security rules that do not cascade to subcollections. All of these are well-documented pitfalls with known prevention strategies. The research consistently points to a 5-phase build order: protocol extraction, auth protocol with UI, Firebase SDK integration, Firestore data layer, and testing/polish.

## Key Findings

### Recommended Stack

The Firebase Apple SDK (v12.9.0) via Swift Package Manager is the clear choice. It provides managed auth (email/password with automatic keychain session persistence), a NoSQL document database with built-in offline caching and Codable support, and eliminates all backend work. The existing models (`Transaction`, `Category`, `UserProfile`) already conform to `Codable`, which means zero-boilerplate Firestore mapping via `FirebaseFirestoreSwift`. No CocoaPods, no custom auth, no Realtime Database -- Firestore is the recommended database for all new Firebase projects, and SPM is the officially recommended installation method.

**Core technologies:**
- **Firebase Auth (12.9.0):** Email/password authentication with automatic keychain persistence -- eliminates custom token management
- **Firebase Firestore (12.9.0):** Per-user persistent data via subcollections at `users/{uid}/transactions` -- natural data isolation
- **FirebaseFirestoreSwift (12.9.0):** Codable encoder/decoder for Firestore -- existing models map with zero boilerplate
- **XCTest with protocol mocks:** Built-in testing with hand-written mocks -- no external test dependencies needed
- **Swift Package Manager:** Built-in Xcode dependency management -- Firebase's primary installation method

### Expected Features

The migration adds authentication and persistence to an already-functional expense tracker. All table-stakes features are standard Firebase patterns: registration (email/password plus name, gender, phone), login, logout, session persistence, auth state observation, and per-user data scoping via Firestore subcollections. The differentiator is the protocol-based architecture that makes the entire system testable without Firebase SDK.

**Must have (table stakes):**
- Email/Password Registration (Name, Gender, Phone, Email, Password) -- users expect their data to persist
- Email/Password Login -- users expect to return to their data after closing the app
- Logout with full state cleanup -- shared devices require account switching
- Session Persistence -- automatic via Firebase keychain, no custom code
- Auth State Listener with conditional navigation -- root view switches between auth flow and main app
- Per-User Data Scoping -- Firestore subcollections `users/{uid}/transactions`
- Auth Error Handling -- typed `AuthError` enum mapped to user-facing strings
- Loading States During Auth -- visual feedback during Firebase network calls

**Should have (competitive):**
- Protocol-Based Service Abstraction -- enables testing without Firebase, makes the Firebase swap a single wiring change
- 80% Unit Test Coverage on ViewModels/Services -- correctness guarantee via XCTest with protocol mocks
- Firestore Codable Integration -- zero-boilerplate data mapping using existing Codable models

**Defer (v2+):**
- Password Reset, Email Verification -- add when users request them; trivial with Firebase APIs
- OAuth/Social Login, Biometric Auth -- protocol-based architecture makes these single new conformances later
- Real-Time Sync -- use one-time fetches for v1; swap to snapshot listeners when multi-device is needed

### Architecture Approach

The architecture adds a protocol layer between ViewModels and the existing `DataService`. ViewModels accept `DataServiceProtocol` and `AuthServiceProtocol` via initializer injection. Production uses `FirebaseAuthService` and `FirestoreDataService`; tests use `MockAuthService` and `MockDataService`. `AuthGateView` at the root observes auth state and conditionally renders the login flow or the main tab view. `FirestoreDataService` observes auth state changes to attach and detach per-user Firestore listeners. The existing `NotificationCenter` cross-ViewModel communication pattern continues, with the trigger shifting from local array mutations to Firestore snapshot listener callbacks.

**Major components:**
1. **AuthServiceProtocol / FirebaseAuthService** -- auth abstraction and Firebase Auth implementation; publishes `AuthState` enum (loading, authenticated, unauthenticated)
2. **DataServiceProtocol / FirestoreDataService** -- data abstraction and Firestore implementation; scopes all reads/writes to `users/{uid}/` paths
3. **AuthViewModel + AuthGateView** -- auth UI state management and root-level conditional navigation
4. **MockDataService + MockAuthService** -- test infrastructure enabling 80% coverage without Firebase SDK

### Critical Pitfalls

1. **Auth state race condition on app launch** -- Using `Auth.auth().currentUser` directly shows the login screen to authenticated users because keychain restoration is async. Use `addStateDidChangeListener` with a three-state `AuthState` enum starting at `.loading`.
2. **Protocol extraction skipped or done after Firebase** -- Directly coupling ViewModels to Firebase types makes 80% coverage unachievable. Extract protocols first, verify existing behavior, then implement Firebase as a conforming service.
3. **Firestore security rules not cascading to subcollections** -- Rules on `users/{uid}` do not cover `users/{uid}/transactions`. Use recursive wildcard `match /users/{uid}/{document=**}` or explicit subcollection matchers.
4. **Registration atomicity failure** -- Auth user created but Firestore profile write fails leaves an orphaned account. Implement rollback: delete the Auth user if the profile write fails.
5. **Offline cache shows previous user's data after sign-out** -- Firestore persistence is global. Call `clearPersistence()` in the sign-out flow after detaching all listeners.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Protocol Extraction
**Rationale:** Everything else depends on protocols. Without `DataServiceProtocol`, ViewModels cannot be tested in isolation and Firebase cannot be swapped in cleanly. This phase touches no Firebase code and verifies all existing behavior still works.
**Delivers:** Testable ViewModels, mock service infrastructure, passing unit tests for all existing logic
**Addresses:** Features -- Protocol-Based Service Abstraction, Unit Test Coverage (foundation)
**Avoids:** Pitfall 2 (protocol extraction skipped after Firebase implementation)

### Phase 2: Auth Protocol and UI
**Rationale:** Auth protocol and views can be built with a mock auth service, allowing UX iteration before any Firebase configuration. The auth state listener pattern is established here and consumed by all subsequent phases.
**Delivers:** `AuthServiceProtocol`, `AuthViewModel`, `LoginView`, `RegisterView`, `AuthGateView`, auth unit tests
**Uses:** `AuthServiceProtocol` abstraction, existing theme/color system
**Implements:** Auth state observation pattern, conditional navigation
**Avoids:** Pitfall 1 (auth state race condition -- `.loading` state from the start)

### Phase 3: Firebase SDK Integration
**Rationale:** Firebase SDK is added and configured only after protocols and auth UI are ready. This phase implements `FirebaseAuthService` conforming to the existing protocol, so it is purely a new service file plus wiring changes. No ViewModel or View changes needed.
**Delivers:** Working Firebase Auth (register, login, logout, session persistence), `AppDelegate` with `FirebaseApp.configure()`, `GoogleService-Info.plist` configuration
**Uses:** Firebase Auth SDK (12.9.0), SPM installation, `addStateDidChangeListener`
**Implements:** `FirebaseAuthService: AuthServiceProtocol`
**Avoids:** Pitfall 4 (registration atomicity -- rollback in `signUp` method)

### Phase 4: Firestore Data Layer
**Rationale:** Firestore requires a user UID for subcollection paths, so it must come after auth works. This is the riskiest phase (data migration, security rules, cache behavior) and benefits from all tests being in place.
**Delivers:** `FirestoreDataService: DataServiceProtocol`, per-user data scoping, Firestore security rules, default category seeding, UserProfile extended with registration fields
**Uses:** FirebaseFirestore SDK (12.9.0), FirebaseFirestoreSwift for Codable, Firestore subcollections
**Implements:** Per-user data isolation, snapshot listener management, sign-out cache clearing
**Avoids:** Pitfalls 3 (security rules), 5 (cache leak), 6 (Date/Timestamp mismatch), 7 (listener leaks)

### Phase 5: Testing and Polish
**Rationale:** With all components in place, this phase focuses on integration testing, error handling, edge cases, and hitting the 80% coverage target.
**Delivers:** Integration tests, error handling for network/auth/Firestore failures, 80% code coverage on ViewModels and Services, edge case handling (offline, concurrent edits)
**Uses:** XCTest, protocol mocks, Xcode code coverage reporting
**Implements:** Full test suite, "looks done but isn't" checklist verification
**Avoids:** All pitfalls via end-to-end verification

### Phase Ordering Rationale

- **Protocols before Firebase** is the single most important ordering decision. Protocols enable testing without Firebase SDK, and make Firebase just another implementation. This is universally recommended in the research.
- **Auth views before Firebase Auth** allows UX iteration without waiting for Firebase console setup. The mock auth service lets you test the full login/register flow immediately.
- **Firebase Auth before Firestore** because Firestore paths require a user UID. Auth must resolve before data can be scoped.
- **Firestore last among new code** because it is the riskiest change. All tests from phases 1-2 provide a safety net.
- **Testing phase at the end** consolidates integration testing and coverage measurement after all components are wired.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 3 (Firebase SDK Integration):** Firebase Console setup steps (project creation, Auth enablement, GoogleService-Info.plist download) are operational, not architectural. May need a setup checklist.
- **Phase 4 (Firestore Data Layer):** Codable round-trip behavior for `UUID` (encoded as string by default) and `Date` (auto-converted to `Timestamp`) should be validated with a small test before full implementation. Security rules deployment process may need clarification.

Phases with standard patterns (skip research-phase):
- **Phase 1 (Protocol Extraction):** Pure refactoring, no external dependencies. Well-documented Swift patterns.
- **Phase 2 (Auth Protocol and UI):** Standard SwiftUI form + ObservableObject. No external dependencies.
- **Phase 5 (Testing and Polish):** XCTest with protocol mocks is well-documented and the patterns are established in earlier phases.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Firebase SDK 12.9.0 verified via official GitHub releases. SPM installation is the officially recommended method. All version compatibility confirmed for iOS 18.5+ target. |
| Features | HIGH | All table-stakes features are standard Firebase patterns with official documentation. Feature prioritization derived from PROJECT.md requirements. Anti-features clearly identified with rationale. |
| Architecture | HIGH | Protocol-based DI is a well-established Swift pattern. MVVM with ObservableObject matches existing codebase. Firestore subcollections for per-user scoping is the standard Firebase data model. |
| Pitfalls | HIGH | All 7 critical pitfalls sourced from official Firebase documentation and verified against the codebase. Prevention strategies are concrete and phase-mapped. |

**Overall confidence:** HIGH

### Gaps to Address

- **UUID encoding in Firestore:** Swift `UUID` is not natively handled by Firestore Codable. It encodes as a string by default, which should work, but round-trip equality needs a dedicated test. Handle during Phase 4 planning with a quick encode/decode spike.
- **`GoogleService-Info.plist` distribution:** The file must not be committed to git but must be present in the Xcode project for builds. The development workflow (how each developer gets the file) should be documented. Handle during Phase 3 with a setup script or README note.
- **UserDefaults vs Firestore for settings:** Currency and theme currently use `@AppStorage` (UserDefaults). After auth, these are device-local, not user-scoped. The research recommends accepting this limitation for v1 and documenting it. Revisit if multi-device users report missing settings.
- **Firestore snapshot listener vs one-time fetch:** The architecture research shows snapshot listeners for real-time updates, but the features research recommends one-time `getDocuments` fetches for a single-user single-device app. This decision should be made explicitly during Phase 4 planning. Recommendation: use one-time fetches for v1 (simpler, fewer pitfalls, lower billing), with a documented path to snapshot listeners later.

## Sources

### Primary (HIGH confidence)
- Firebase Apple SDK GitHub Releases -- version 12.9.0 verified (https://github.com/firebase/firebase-ios-sdk/releases)
- Firebase iOS Setup Documentation -- SPM installation, SwiftUI initialization (https://firebase.google.com/docs/ios/setup)
- Firebase Auth Password Authentication Docs -- register/login/signOut APIs (https://firebase.google.com/docs/auth/ios/password-auth)
- Firebase Firestore Quickstart Docs -- CRUD operations, subcollections (https://firebase.google.com/docs/firestore/quickstart)
- Firestore Data Modeling (Subcollections) -- per-user data scoping (https://firebase.google.com/docs/firestore/manage-data/structure-data)
- Firestore Security Rules Guide -- cascading rules, secure patterns (https://firebase.google.com/docs/firestore/security/get-started)
- Firestore Best Practices -- Codable integration, offline persistence (https://firebase.google.com/docs/firestore/best-practices)
- PROJECT.md requirements -- protocol-first approach, 80% coverage target, registration fields

### Secondary (MEDIUM confidence)
- Existing codebase analysis -- DataService.swift, all ViewModels, all Models, ExpenseTrackerAppApp.swift
- Firebase AuthErrorCode reference -- error code mapping for user-facing messages
- Codebase architecture documentation -- `.planning/codebase/ARCHITECTURE.md`

### Tertiary (LOW confidence)
- Competitor feature analysis (Splitwise, YNAB, Goodbudget) -- general patterns, not directly actionable for this project's scope
- Firestore scaling thresholds (10K+ users) -- not relevant for MVP but useful for future planning

---
*Research completed: 2026-04-05*
*Ready for roadmap: yes*

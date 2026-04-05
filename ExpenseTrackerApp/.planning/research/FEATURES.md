# Feature Research

**Domain:** Firebase Auth + Firestore migration for SwiftUI expense tracker (iOS)
**Researched:** 2026-04-05
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in any app requiring login. Missing these = users delete the app or refuse to register.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Email/Password Registration | Every app with accounts has this; users will not use an expense tracker that loses their data | MEDIUM | Collect Name, Gender, Phone Number, Email, Password. Two-step: create Auth user then write profile to Firestore `users/{uid}/profile`. Firebase `createUser(withEmail:password:completion:)`. |
| Email/Password Login | Users expect to return to their data after closing the app | LOW | Firebase `signIn(withEmail:password:completion:)`. Single call, straightforward. |
| Logout | Users expect account control; shared devices require it | LOW | Firebase `signOut()` plus clear local state. Must reset DataService in-memory arrays so stale data does not persist. |
| Session Persistence | Users will not re-login every launch; they expect "it just works" | LOW | Firebase handles this automatically via iOS keychain token storage. `Auth.auth().currentUser` is non-nil on relaunch. No code needed beyond the listener. |
| Auth State Listener | App must show login screen for unauthenticated users, main app for authenticated ones | LOW | `Auth.auth().addStateDidChangeListener` in a root-level observable. SwiftUI conditional view switching based on `isAuthenticated` published property. |
| Per-User Data Scoping | Users must never see another user's transactions | MEDIUM | Firestore subcollections: `users/{uid}/transactions`. Security rules enforce `request.auth.uid == resource.data.userId`. DataService must load/write only the authenticated user's subcollection. |
| Password Validation (Registration) | Users expect guardrails: minimum length, confirmation match | LOW | Client-side validation before Firebase call. 6-character minimum enforced by Firebase anyway; add confirm-password field and visual feedback inline. |
| Auth Error Handling | Users need clear messages: "wrong password", "email already in use", "network error" | MEDIUM | Map `AuthErrorCode` to user-facing strings. Common errors: `.emailAlreadyInUse`, `.wrongPassword`, `.userNotFound`, `.networkError`. Present via alert or inline text, never raw Firebase error messages. |
| Loading States During Auth | Users expect visual feedback during login/register (spinner, disabled button) | LOW | `@Published var isLoading: Bool` on AuthViewModel. Disable form buttons, show ProgressView during Firebase calls. Prevents duplicate submissions. |

### Differentiators (Competitive Advantage)

Features that set this project apart from typical tutorial-level Firebase integrations. Not expected by users, but they make the codebase maintainable and professional.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Protocol-Based Service Abstraction | Enables unit testing without Firebase SDK; ViewModels become testable in isolation | MEDIUM | Extract `DataServiceProtocol` and `AuthServiceProtocol` before Firebase work. Current `DataService` becomes the first conformant. `FirebaseDataService` becomes the second. ViewModels accept protocols, not concrete types. This is the single highest-impact architectural decision for the project. |
| 80% Unit Test Coverage on ViewModels/Services | Guarantees correctness of business logic; catches regressions when Firebase implementation changes | MEDIUM | XCTest with protocol mocks (no Firebase SDK in test target). Test all ViewModel computed properties, filter/sort logic, CRUD delegation, auth state transitions. Current zero-coverage codebase means every test is new value. |
| AuthViewModel with Combine Publisher | Reactive auth state propagated to all views automatically | LOW | `@Published var isAuthenticated: Bool` plus `@Published var currentUser: User?`. Views observe these. No manual state synchronization needed. Replaces ad-hoc notification pattern with clean reactive flow. |
| Clean Error Type for Auth | Typed errors instead of raw NSError strings; testable error paths | LOW | Define `AuthError` enum: `.invalidEmail`, `.weakPassword`, `.emailAlreadyInUse`, `.wrongPassword`, `.userNotFound`, `.networkError`, `.unknown(Error)`. Map Firebase errors once at the service boundary. ViewModels and tests deal only with `AuthError`. |
| Firestore Codable Integration | Models already conform to `Codable` (Transaction, Category, UserProfile); direct Firestore document mapping with zero boilerplate | LOW | `try Firestore.Encoder().encode(transaction)` and `try Firestore.Decoder().decode(Transaction.self, from: document)`. Current models need only minor adjustments: `Date` maps to `Timestamp` automatically, `UUID` needs a custom encoder to string. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem like natural additions but create disproportionate complexity for this milestone.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| OAuth/Social Login (Google, Apple) | "Everyone uses Google/Apple sign-in" | Adds multiple dependency configurations (Google Sign-In SDK, Sign in with Apple capability), different auth flows per provider, separate credential handling. Doubles the auth code for marginal UX gain in a personal expense tracker. | Ship Email/Password first. Add OAuth in a future milestone when users request it. The protocol-based `AuthServiceProtocol` makes this a single new conformance later. |
| Biometric Auth (Face ID/Touch ID) | "Modern apps use Face ID" | Requires LocalAuthentication framework, fallback to password, handling LAError codes, device capability checks. Adds a whole auth dimension before basic auth works. | Defer. Protocol extraction means `BiometricAuthService` can wrap `AuthService` later without touching ViewModels. |
| Email Verification | "We should verify emails" | Adds email sending config in Firebase Console, requires handling verified/unverified states throughout the app, "resend verification" flow. Firebase sends templated emails that look unprofessional without custom setup. | Skip for v1. User registered = user verified. Add verification requirement in a future milestone when spam becomes an issue. |
| Password Reset | "Users forget passwords" | Requires dedicated UI flow (enter email, send reset, check email, return to app), Firebase email template configuration. Adds a full navigation branch before core auth is stable. | Defer. Mark `passwordReset` as a method on `AuthServiceProtocol` with a TODO. Trivial to add later since Firebase handles the server-side logic. |
| Real-Time Firestore Listeners | "Transactions should sync in real-time" | `addSnapshotListener` on transactions means live sync across devices. For a single-user, single-device expense tracker this is unnecessary complexity. Snapshot listeners require careful memory management (must store and remove listener handles), conflict resolution for offline writes, and complicate testing. | Use one-time `getDocuments` fetches. Add real-time listeners only when multi-device sync becomes a requirement. The Firestore service can swap `getDocuments` for `addSnapshotListener` without ViewModel changes. |
| Offline-First with Merge Conflicts | "It should work offline" | Firestore has built-in offline persistence, but explicit offline-first design requires conflict resolution strategy, queue management, and UI for sync status. Premature for a v1 that does not even have online persistence yet. | Enable Firestore's default offline cache (one line of config). Do not design for explicit offline-first. The default cache handles airplane-mode usage well enough. |
| Custom Firebase Auth UI | "FirebaseUI looks generic" | FirebaseUI for iOS is a prebuilt auth screen library. It conflicts with custom SwiftUI design, adds an opaque dependency, and the registration fields (Name, Gender, Phone) do not match FirebaseUI's standard templates. | Build custom SwiftUI auth views. The project already has a design language (theme colors, Constants). Custom views give full control over the registration field set and are more testable via SwiftUI previews. |

## Feature Dependencies

```
Protocol Extraction (DataServiceProtocol + AuthServiceProtocol)
    |
    ├──required-by──> Unit Test Infrastructure (mocks depend on protocols)
    |                       |
    |                       └──required-by──> 80% Coverage Target
    |
    └──enables──> Firebase Service Implementation
                      |
                      ├──contains──> Firebase Auth (register, login, logout)
                      |                    |
                      |                    └──required-by──> Auth State Listener
                      |                                          |
                      |                                          └──required-by──> Conditional Navigation (auth vs main app)
                      |
                      └──contains──> Firestore Data Service
                                           |
                                           ├──required-by──> Per-User Data Scoping (subcollections)
                                           |
                                           └──requires──> Auth (need UID for subcollection path)

Registration (Name, Gender, Phone, Email, Password)
    └──requires──> Firebase Auth + Firestore Profile Write

Login (Email, Password)
    └──requires──> Firebase Auth Only

Auth Error Types ──enhances──> All Auth Operations (consistent error handling)

Codable Models ──enhances──> Firestore Integration (zero-boilerplate mapping)
```

### Dependency Notes

- **Protocol Extraction must precede everything else:** Without `DataServiceProtocol`, ViewModels depend on the concrete `DataService` singleton. Tests cannot inject mocks. Firebase service cannot be swapped in. This is the keystone architectural change.
- **Unit Tests depend on Protocol Extraction:** Mock objects conform to `DataServiceProtocol` and `AuthServiceProtocol`. Tests instantiate ViewModels with mock services. Without protocols, there is no seam for injection.
- **Firestore Data Service requires Auth UID:** The Firestore path `users/{uid}/transactions` needs the authenticated user's UID. Firestore service cannot load data until auth resolves. DataService init must accept UID or receive it after auth state changes.
- **Auth State Listener must precede Conditional Navigation:** The root view needs an `isAuthenticated` observable to decide between LoginView and MainTabView. The listener publishes this state.
- **Registration is a two-write operation:** Firebase Auth `createUser` creates the auth record. A separate Firestore `setData` writes the profile document (Name, Gender, Phone). Both must succeed; partial failure (auth created but profile write fails) must be handled.
- **Codable Models enhance Firestore but are not blocking:** Transaction, Category, and UserProfile already conform to `Codable`. Minor adjustments needed (UUID string encoding, Date-Timestamp handling) but no structural model changes required.

## MVP Definition

### Launch With (v1 -- This Milestone)

Minimum viable product -- what is needed to deliver the PROJECT.md requirements.

- [ ] `DataServiceProtocol` -- Extract protocol from existing DataService; DataService conforms to it. Enables testing and Firebase swap.
- [ ] `AuthServiceProtocol` -- Define protocol with register, login, logout, state listener. FirebaseAuthService conforms to it.
- [ ] Email/Password Registration (Name, Gender, Phone, Email, Password) -- Custom SwiftUI form writing to Firebase Auth + Firestore profile.
- [ ] Email/Password Login -- Custom SwiftUI form calling Firebase Auth signIn.
- [ ] Logout -- Firebase signOut plus DataService state reset.
- [ ] Session Persistence -- Rely on Firebase automatic keychain persistence; add state listener on app launch.
- [ ] Auth State Listener + Conditional Navigation -- Root view switches between auth flow and main app based on `isAuthenticated`.
- [ ] Firestore Per-User Transactions -- `users/{uid}/transactions` subcollection. Load on auth, write on CRUD.
- [ ] Firestore Per-User Profile -- `users/{uid}/profile` document. Read/write during registration and settings changes.
- [ ] Auth Error Types + User-Facing Messages -- Map Firebase errors to `AuthError` enum, display localized strings.
- [ ] Unit Tests for AuthViewModel -- Registration validation, login flow, logout flow, error mapping, state transitions.
- [ ] Unit Tests for DashboardViewModel -- Balance calculations, recent transactions, category lookup (using mock DataService).
- [ ] Unit Tests for TransactionViewModel -- Filtering, sorting, search, CRUD delegation (using mock DataService).
- [ ] Unit Tests for SettingsViewModel -- Currency and theme changes (using mock DataService).
- [ ] Unit Tests for Services -- DataServiceProtocol mock behavior, AuthServiceProtocol mock behavior.

### Add After Validation (Future Milestones)

Features to add once core auth + persistence is working and tested.

- [ ] Password Reset -- Add `sendPasswordReset(email:)` to AuthServiceProtocol. Single new view. Trigger: user feedback asking for it.
- [ ] Email Verification -- Add `sendEmailVerification()` after registration. Add verified-state checks. Trigger: spam or fake account issues.
- [ ] Biometric Auth -- LocalAuthentication wrapper in AuthServiceProtocol. Trigger: user feedback requesting Face ID.
- [ ] OAuth (Google/Apple) -- New credential-based auth methods in AuthServiceProtocol. Trigger: user feedback requesting social login.

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Real-Time Sync -- Swap `getDocuments` for `addSnapshotListener`. Trigger: multi-device usage requests.
- [ ] Data Export -- CSV/PDF export of transactions. Not in current scope.
- [ ] Multi-Currency -- Currently single currency per user. Would require exchange rate integration.
- [ ] Budget Management -- Removed in v2.0, explicitly out of scope.

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Protocol Extraction (DataServiceProtocol) | INDIRECT (enables tests and Firebase swap) | MEDIUM | P1 |
| Protocol Extraction (AuthServiceProtocol) | INDIRECT (enables tests and auth service) | LOW | P1 |
| Email/Password Registration | HIGH | MEDIUM | P1 |
| Email/Password Login | HIGH | LOW | P1 |
| Logout | HIGH | LOW | P1 |
| Session Persistence | HIGH | LOW (automatic) | P1 |
| Auth State Listener + Conditional Nav | HIGH | LOW | P1 |
| Per-User Firestore Data Scoping | HIGH | MEDIUM | P1 |
| Auth Error Handling | MEDIUM | MEDIUM | P1 |
| Loading States | MEDIUM | LOW | P1 |
| Unit Tests (ViewModels) | INDIRECT (correctness guarantee) | MEDIUM | P1 |
| Unit Tests (Services) | INDIRECT (correctness guarantee) | LOW | P1 |
| Clean Auth Error Types | LOW (UX polish) | LOW | P2 |
| Firestore Codable Integration | INDIRECT (developer efficiency) | LOW | P2 |
| Password Reset | MEDIUM | LOW | P3 |
| Email Verification | LOW | MEDIUM | P3 |
| Biometric Auth | MEDIUM | MEDIUM | P3 |
| OAuth/Social Login | LOW | HIGH | P3 |
| Real-Time Firestore Sync | LOW | MEDIUM | P3 |

**Priority key:**
- P1: Must have for this milestone (all PROJECT.md active requirements)
- P2: Should have, adds quality with low cost
- P3: Future milestones, explicitly deferred in PROJECT.md

## Competitor Feature Analysis

| Feature | Splitwise | YNAB | Goodbudget | Our Approach |
|---------|-----------|------|------------|--------------|
| Registration | Email + password, OAuth (Google, Apple, Facebook) | Email + password, OAuth (Google, Apple, Facebook) | Email + password, Google OAuth | Email + password only. Simpler. Protocol enables adding OAuth later. |
| Login Persistence | Automatic (Firebase Auth) | Automatic | Automatic | Rely on Firebase automatic keychain persistence. Zero custom code. |
| Per-User Data | Cloud-scoped per account | Cloud-scoped per account | Cloud-scoped per account | Firestore subcollections `users/{uid}/transactions`. Standard Firebase pattern. |
| Offline Support | Limited | Full offline-first with sync | Limited | Enable Firestore default cache only. No explicit offline-first design. |
| Error Messages | Generic "Something went wrong" | Specific inline validation | Generic alerts | Typed `AuthError` enum mapped to specific user-facing strings. Better than competitors at v1. |
| Testing | Unknown (proprietary) | Unknown (proprietary) | Unknown (proprietary) | 80% coverage target on ViewModels/Services. Protocol-based mocks. Open-source quality standard. |

## Sources

- Firebase Auth documentation: https://firebase.google.com/docs/auth/ios/email-password-iam
- Firebase Firestore data model (subcollections): https://firebase.google.com/docs/firestore/data-model
- Firebase Firestore Swift Codable integration: https://firebase.google.com/docs/firestore/best-practices (Techniques: "Map data with Swift Codable")
- Firebase iOS SDK Swift Package Manager setup: https://firebase.google.com/docs/ios/setup
- PROJECT.md requirements: `.planning/PROJECT.md` (active requirements section)
- Existing codebase analysis: DataService.swift, TransactionViewModel.swift, DashboardViewModel.swift, UserProfile.swift, ExpenseTrackerAppApp.swift
- Firebase `AuthErrorCode` reference: https://firebase.google.com/docs/reference/swift/firebaseauth/api/reference/Enums/AuthErrorCode

---
*Feature research for: ExpenseTrackerApp Firebase Auth + Firestore Migration*
*Researched: 2026-04-05*

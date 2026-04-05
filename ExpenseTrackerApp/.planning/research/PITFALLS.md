# Pitfalls Research

**Domain:** Firebase Auth + Firestore on iOS (SwiftUI/Swift)
**Researched:** 2026-04-05
**Confidence:** HIGH (official Firebase documentation, verified codebase analysis)

## Critical Pitfalls

### Pitfall 1: Auth State Race Condition on App Launch

**What goes wrong:**
The app checks `Auth.auth().currentUser` once during `@main` App init to decide whether to show the login screen or the main tab view. Firebase Auth asynchronously restores the cached session from the keychain. The one-time check returns `nil` because the listener has not fired yet, so an already-logged-in user sees the login screen for a split second (or permanently if the view does not re-evaluate).

**Why it happens:**
Developers treat `Auth.auth().currentUser` like a synchronous property. Firebase recommends `addStateDidChangeListener` specifically because session restoration is asynchronous. The singleton `currentUser` is `nil` until the keychain lookup completes.

**How to avoid:**
Use `Auth.auth().addStateDidChangeListener` in an `ObservableObject` (e.g., `AuthViewModel`). Store the resulting `User?` in a `@Published` property. The SwiftUI view hierarchy reads this published property, not `Auth.auth().currentUser`. Handle the intermediate "loading" state (listener has not fired yet) with a splash screen or progress view so users never see the wrong screen.

**Warning signs:**
- Login screen flashes briefly on relaunch for authenticated users
- `Auth.auth().currentUser` used directly in view `body` or `onAppear`
- No loading/splash state between app launch and auth resolution
- Tests that only check `currentUser` after creating a user synchronously

**Phase to address:**
Phase 1 (Auth Service + Protocol Extraction) — the `AuthServiceProtocol` must define `addStateDidChangeListener` behavior, and the `AuthViewModel` must publish a three-state enum: `loading`, `authenticated`, `unauthenticated`.

---

### Pitfall 2: Protocol Extraction Skipped or Done After Firebase Implementation

**What goes wrong:**
Developers implement `FirebaseDataService` directly by modifying the existing `DataService` class. This couples ViewModels to Firebase types (`Firestore`, `DocumentReference`, `Timestamp`), making unit testing impossible without a real Firebase connection. The milestone requirement of 80% code coverage on ViewModels/Services becomes unachievable.

**Why it happens:**
It feels faster to "just make it work with Firebase" than to design protocol interfaces first. The existing codebase already couples ViewModels to the concrete `DataService` type (not a protocol), so the path of least resistance is modifying `DataService` in-place.

**How to avoid:**
Strict ordering: (1) Extract `DataServiceProtocol` from the existing `DataService` with all current method signatures. (2) Make `DataService` conform to it. (3) Change all ViewModel initializers to accept `DataServiceProtocol` instead of `DataService`. (4) Verify existing functionality still works (all in-memory behavior unchanged). (5) Only then create `FirebaseDataService: DataServiceProtocol`. This is explicitly noted in PROJECT.md as the correct approach.

**Warning signs:**
- ViewModels importing `FirebaseFirestore` or `FirebaseAuth`
- Test files that create real `Firestore` or `Auth` instances
- Default parameter values in ViewModel `init` referencing `FirebaseDataService` instead of a protocol
- Inability to run tests without network or Firebase emulator

**Phase to address:**
Phase 1 (Protocol Extraction) — this is the foundational step. If skipped here, every subsequent phase inherits the coupling problem.

---

### Pitfall 3: Firestore Security Rules Do Not Cascade to Subcollections

**What goes wrong:**
Security rules are written for `users/{uid}` documents but the app stores data in `users/{uid}/transactions/{transactionId}` subcollections. Rules on the parent document do NOT automatically apply to subcollections. Users can read and write any other user's transactions, or no one can read their own.

**Why it happens:**
Firestore security rules match specific paths. A rule matching `match /users/{uid}` only applies to the user document itself, not to subcollections beneath it. Developers assume hierarchical inheritance like filesystem permissions. To cover subcollections, you need either a recursive wildcard `match /users/{uid}/{document=**}` or explicit `match /users/{uid}/transactions/{transactionId}` rules.

**How to avoid:**
Write security rules explicitly for each subcollection path. For this project's schema (`users/{uid}/transactions` and `users/{uid}/profile`), write:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```
Test rules in the Firebase console simulator with authenticated and unauthenticated requests before deploying.

**Warning signs:**
- Security rules only have `match /users/{uid}` without subcollection matchers
- No rules tests in the Firebase emulator
- App works in development (open rules) but fails in production
- Permission denied errors appear only on transaction operations, not user profile reads

**Phase to address:**
Phase 2 (Firestore Data Service) — write security rules alongside the `FirebaseDataService` implementation. Deploy rules before testing with real Firestore.

---

### Pitfall 4: Registration Atomicity Failure (Auth User Created But Firestore Profile Write Fails)

**What goes wrong:**
The registration flow calls `Auth.auth().createUser(withEmail:password:)` successfully, creating a Firebase Auth user. Then the app writes the additional profile data (name, gender, phone number) to Firestore `users/{uid}/profile`. If this Firestore write fails (network error, permission issue, malformed data), the Auth user exists but has no profile. Subsequent login succeeds but the app shows empty or broken profile state.

**Why it happens:**
Firebase Auth user creation and Firestore writes are two separate operations. There is no transaction spanning Auth and Firestore. Developers treat registration as a single atomic operation when it is not.

**How to avoid:**
Use a `Credential`-based approach: (1) Create the Auth user. (2) In the completion handler, immediately write the profile to Firestore. (3) If the Firestore write fails, delete the Auth user with `user.delete()` to roll back. (4) Alternatively, use a Cloud Function triggered by `onCreate` in Auth to write the profile document, guaranteeing it always happens. For this project's scope (no Cloud Functions), the rollback approach is simpler. Always wrap the Firestore profile write in a `do/catch` with cleanup on failure.

**Warning signs:**
- Users in Firebase Auth console with no corresponding Firestore profile document
- App crashes or shows blank name/gender/phone after fresh registration
- No error handling after `createUser` completion beyond logging
- Registration "succeeds" but login shows a broken UI

**Phase to address:**
Phase 1 (Auth Service) — the `register` method in `FirebaseAuthService` must handle rollback. Tests must cover the "Auth succeeds, Firestore fails" path.

---

### Pitfall 5: Offline Persistence Cache Shows Previous User's Data After Sign-Out

**What goes wrong:**
Firestore offline persistence is enabled by default on iOS. User A logs in, their transactions are cached locally. User A logs out, User B logs in on the same device. The cache still contains User A's data. The app briefly shows User A's transactions to User B, or throws permission-denied errors when trying to read User B's data from the stale cache.

**Why it happens:**
Firestore's persistence layer is global to the `Firestore` instance. When users switch, the cached documents from the previous user remain until they are evicted or overwritten. The `isFromCache` metadata flag is rarely checked, so the app treats cached data as current.

**How to avoid:**
Call `Firestore.firestore().clearPersistence()` in the sign-out flow AFTER `Auth.auth().signOut()`. This requires first disabling any active listeners. Alternatively, check `snapshot.metadata.isFromCache` on every read and discard cached results that do not belong to the current user. The simpler approach for this project: clear persistence on sign-out, and verify the Firestore `db` settings use `PersistentCacheSettings` with a reasonable size limit.

**Warning signs:**
- After sign-out and re-login with a different account, previous user's transactions appear briefly
- Firestore permission-denied errors after user switch
- No `clearPersistence()` or `disableNetwork()`/`enableNetwork()` calls in sign-out flow
- Listeners from previous session still active (memory leak + stale data)

**Phase to address:**
Phase 2 (Firestore Data Service) — the `FirebaseDataService.logout()` or equivalent method must clear persistence and tear down all active Firestore listeners.

---

### Pitfall 6: Codable Date/Timestamp Mismatch with Firestore

**What goes wrong:**
The `Transaction` model uses `Date` properties and is already `Codable`. Firestore stores dates as `Timestamp` objects. When decoding a Firestore document, the SDK can convert `Timestamp` to `Date` automatically if the field is declared as `Date` in the Codable struct. However, when writing, a plain `Date` is stored as a Firestore `Timestamp`. Problems arise with `@ServerTimestamp` sentinel values, nullable date fields, and custom `CodingKeys` that do not align with Firestore field names.

**Why it happens:**
Swift `Date` and Firestore `Timestamp` are different types. The Firestore SDK handles the conversion for simple cases but fails silently or throws opaque errors for edge cases: optional dates, arrays of dates, dates inside nested objects, and dates used in `FieldValue.serverTimestamp()`. The existing `Transaction` model has a `date` property that must map correctly.

**How to avoid:**
Use `FirebaseFirestoreSwift` module's `@DocumentID` and timestamp handling. For the `Transaction` model: keep `Date` types in the model, let Firestore's `Codable` support handle conversion. Do NOT use `FieldValue.serverTimestamp()` on fields the client writes (like transaction date). Reserve server timestamps for `createdAt`/`updatedAt` metadata fields only. Write a unit test that round-trips a `Transaction` through Firestore encode/decode to verify `Date` survives correctly.

**Warning signs:**
- Transactions appear with wrong dates (epoch zero, or far-future dates)
- Decoding errors mentioning "Timestamp" or "doubleValue" type mismatch
- `CodingKeys` enum defined but missing the date field
- Model has custom `init(from decoder:)` that does not handle `Timestamp`

**Phase to address:**
Phase 2 (Firestore Data Service) — write encode/decode round-trip tests for `Transaction` and `UserProfile` models before building any UI against Firestore data.

---

### Pitfall 7: Uncontrolled Firestore Listeners Leak Memory and Generate Billable Reads

**What goes wrong:**
Each call to `db.collection(...).addSnapshotListener` creates an active realtime connection. If ViewModels attach listeners in `init` or `onAppear` without removing them in `deinit` or `onDisappear`, listeners accumulate. Every document change triggers a billable read. After navigating back and forth between views, the app has dozens of duplicate listeners, each charging per update.

**Why it happens:**
`addSnapshotListener` returns a `ListenerRegistration` object that must be explicitly removed. SwiftUI view lifecycle makes this tricky: `onAppear`/`onDisappear` can fire multiple times, and `@StateObject` ViewModels persist across view appearances. The current codebase uses `NotificationCenter` observers with proper `cancellable` cleanup in ViewModels, but Firestore listeners follow a different pattern.

**How to avoid:**
Store each `ListenerRegistration` in the ViewModel and call `.remove()` in `deinit` or when explicitly detaching. Use a helper method that removes the previous listener before adding a new one. For this project's MVVM pattern: the `FirebaseDataService` (or ViewModel) should manage listener registration objects as instance properties. Consider using Combine's `Future`/`Promise` with single-fetch (`getDocuments`) instead of realtime listeners for transaction lists, since the app currently only needs fresh data on explicit load, not realtime push updates.

**Warning signs:**
- Firestore usage dashboard shows read counts climbing far faster than expected
- Memory usage grows as user navigates between views
- `deinit` not being called on ViewModels (retain cycle from listener closures capturing `self`)
- Same transaction data appearing multiple times in lists

**Phase to address:**
Phase 2 (Firestore Data Service) — decide early whether to use realtime listeners or one-time fetches. Document the decision. If listeners, implement registration management from day one.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip protocol extraction, use `DataService` directly | Ship Firebase integration faster | Cannot unit test ViewModels, cannot mock Firebase | Never — this milestone requires 80% coverage |
| Use `Auth.auth().currentUser` directly in views | Simpler code, fewer files | Race condition on launch, cannot test auth flows | Never — causes intermittent login screen flash |
| Open Firestore rules (`allow read, write: if true`) during development | No permission errors while building | Leaks to production if forgotten, exposes all user data | Only in local emulator with `FIRESTORE_EMULATOR_HOST` set; never against real Firebase project |
| Store all transactions in a top-level collection with `userId` field | Simpler queries, single collection read | Requires composite indexes, no security rule isolation, harder to shard | Never — project already decided on `users/{uid}/transactions` subcollections |
| Skip sign-out cache clearing | Fewer lines of code, simpler logout | Multi-user device shows wrong data, potential PII leak | Never — privacy issue |
| Use `@AppStorage` for auth state | Familiar API, no Firebase dependency | Does not reflect actual Firebase session, persists after Firebase sign-out | Never for auth state; fine for theme/currency (current usage is correct) |
| Hardcode Firestore field names as strings | Quick to implement | No compile-time safety, refactoring breaks silently | Only in security rules (unavoidable); use `CodingKeys` in Swift models |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Firebase SPM import | Importing only `FirebaseCore`; missing `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreSwift` | Import `FirebaseAuth` for auth, `FirebaseFirestore` for database, `FirebaseFirestoreSwift` for Codable support |
| Firebase initialization | Calling `FirebaseApp.configure()` multiple times or in a View `onAppear` | Call `FirebaseApp.configure()` once in `AppDelegate.init()` or `App.init()` with a guard to prevent re-initialization |
| Firestore Codable | Not using `FirebaseFirestoreSwift` module; trying to manually serialize/deserialize dictionaries | Use `FirebaseFirestoreSwift` and call `try document.data(as: Transaction.self)` for automatic Codable decoding |
| Auth state listener | Adding listener in View `onAppear` without removing in `onDisappear` | Add listener in `ObservableObject.init()`, store registration, remove in `deinit` |
| Firestore writes | Using `setData()` without `merge:` option, overwriting entire document | Use `setData(from: transaction, merge: true)` for updates to avoid deleting fields not in the Codable struct |
| `GoogleService-Info.plist` | Committing the plist to git with API keys | Add to `.gitignore`; use different plists per environment (Debug/Release) or Firebase projects |
| SwiftUI + async Firebase | Calling Firebase APIs from `@MainActor` ViewModels without `await` | Mark Firebase service methods as `async throws` and call with `await` from ViewModel; Firebase SDK callbacks already dispatch to main queue |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Fetching all transactions on every view appear | Loading spinner on every tab switch, increasing load time | Cache transactions in ViewModel, only re-fetch on explicit pull-to-refresh or after mutation | Noticeable with 100+ transactions per user |
| Missing Firestore indexes | Queries fail with "query requires an index" error in console | Create composite indexes in Firebase console for queries filtering on `date` + `categoryId` or `type` + `date` | First time a multi-field query runs in production |
| Realtime listeners on large collections | High read count, battery drain, slow UI updates | Use one-time fetches (`getDocuments`) for transaction lists; use listeners only for auth state | Noticeable at 500+ documents per user per month |
| Decoding large result sets on main thread | UI freezes during data parsing | Decode Firestore documents in background (already on background queue in Firebase callbacks), dispatch to main for `@Published` updates | Noticeable at 1000+ transactions |
| Storing full `Transaction` objects in multiple `@Published` arrays | Memory pressure, duplicate data in `DashboardViewModel` and `TransactionViewModel` | Share data through the `DataServiceProtocol`; ViewModels read from single source of truth | At 500+ transactions |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Rules using `allow read, write: if request.auth != null` (any authenticated user) | Any logged-in user can read/write ALL other users' data | Use `request.auth.uid == uid` to restrict to content-owner-only access |
| No validation of write data in security rules | Malicious client can write arbitrary fields, corrupt schema, or inject huge payloads | Add `request.resource.data` checks: validate field types, restrict writable fields, enforce required fields |
| API keys in `GoogleService-Info.plist` committed to public repo | API keys are not secret but project ID is exposed; abuse potential for unauthenticated API calls | Add `GoogleService-Info.plist` to `.gitignore`; Firebase API keys are restricted by bundle ID but still best to keep private |
| No Firebase App Check enabled | Unverified clients can access Firestore directly | Enable Firebase App Check with DeviceCheck provider after initial development |
| Client-side-only security | All validation in Swift code, none in Firestore rules | Security rules are the server-side enforcement layer; duplicate critical validations there |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No loading state during auth restoration | User sees login screen for 200-500ms then gets redirected, or sees main app briefly then gets kicked to login | Show a splash/loading view until auth listener fires with definitive state |
| Registration form loses all data on error | User fills out Name, Gender, Phone, Email, Password; Firestore profile write fails; form resets | Preserve form state across error, only clear password field, show inline error |
| Silent sign-out (session expired) | User is suddenly on login screen with no explanation, thinks app crashed | Detect `AuthStateDidChangeListener` transition from authenticated to unauthenticated, show brief message |
| Transactions disappear during offline use | User adds transactions while offline, they appear to vanish on next launch because fetch hits server which has none | Enable offline persistence (default on), show cached data, indicate offline status, sync when back online |
| No error feedback on failed CRUD | User taps "Add Transaction", nothing happens (Firestore write failed silently) | Show `Alert` or toast on error, retry logic for network failures |

## "Looks Done But Isn't" Checklist

- [ ] **Auth persistence:** App shows correct screen after force-quit — verify `addStateDidChangeListener` fires before view renders, not just `currentUser` check
- [ ] **Protocol extraction:** ViewModels compile against `DataServiceProtocol`, not `DataService` — verify no `import FirebaseFirestore` in any ViewModel file
- [ ] **Unit tests:** Tests run without network/Firebase connection — verify mocks conform to protocol, tests use mock implementations exclusively
- [ ] **Sign-out cleanup:** After sign-out, no Firestore listeners are active — verify `ListenerRegistration.remove()` called, no stale `@Published` data
- [ ] **Firestore security rules:** Rules deployed to production match local rules — verify rules file in repo matches Firebase console, test with unauthenticated requests
- [ ] **Registration rollback:** Auth user deleted if Firestore profile write fails — verify `user.delete()` called in error path, no orphaned Auth users
- [ ] **Date round-trip:** Transaction date survives Firestore encode/decode — verify `Date` equality after write + read, check timezone handling
- [ ] **Multi-user isolation:** User A cannot read User B's transactions — verify security rules with Firebase rules simulator using different UIDs
- [ ] **Cache clearing:** After sign-out + sign-in as different user, no previous user data shown — verify `clearPersistence()` called, no cached documents from previous session
- [ ] **Coverage target:** 80% coverage on ViewModels and Services actually measured — verify Xcode coverage report, not just "we wrote tests"

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Protocol extraction skipped (concrete Firebase types in ViewModels) | HIGH | Extract protocol retroactively, create mock implementations, refactor all ViewModel constructors, rewrite all tests |
| Security rules not deployed (open access in production) | MEDIUM | Deploy correct rules immediately; audit Firestore access logs for unauthorized reads; notify users if PII exposed |
| Registration creates orphaned Auth users | LOW | Write a one-time script to list Auth users without Firestore profile documents; either create missing profiles or delete orphaned accounts |
| Offline cache shows wrong user data | LOW | Add `clearPersistence()` to sign-out flow in next release; users already affected will clear on next sign-out |
| Codable Date/Timestamp mismatch | MEDIUM | Add explicit `Timestamp` to `Date` conversion in custom `init(from:)` or use `FirebaseFirestoreSwift`; write migration for existing corrupt documents |
| Listener leak (memory + billing) | LOW | Add `ListenerRegistration` management to `FirebaseDataService`; existing leaked listeners die on app restart |
| `GoogleService-Info.plist` committed to git | LOW | Rotate Firebase project settings (new API key), add to `.gitignore`, `git rm --cached` the file |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Auth state race condition | Phase 1: Protocol Extraction + Auth Service | Test: kill app while logged in, relaunch, verify no login screen flash |
| Protocol extraction skipped | Phase 1: Protocol Extraction | Test: grep ViewModels for `import FirebaseFirestore` — should return zero results |
| Security rules not cascading | Phase 2: Firestore Data Service | Test: deploy rules, use Firebase rules simulator with two different UIDs |
| Registration atomicity | Phase 1: Auth Service | Test: mock Firestore to throw on profile write, verify Auth user is deleted |
| Offline cache cross-user leak | Phase 2: Firestore Data Service | Test: sign in as User A, add data, sign out, sign in as User B, verify User A data not visible |
| Codable Date/Timestamp mismatch | Phase 2: Firestore Data Service | Test: encode Transaction, decode from Firestore document, assert Date equality |
| Listener memory/billing leak | Phase 2: Firestore Data Service | Test: navigate between Dashboard and Transactions 10 times, verify listener count does not grow |
| Open security rules in production | Phase 3: Testing + Hardening | Test: rules file reviewed, no `if true` or missing `uid` check, rules simulator passes |
| Missing loading state during auth | Phase 1: Auth Service | Test: add 2-second delay to auth listener, verify splash/loading screen shown |
| Sign-out not cleaning up | Phase 2: Firestore Data Service | Test: sign out, verify no active listeners, no cached data, no stale `@Published` properties |

## Sources

- Firebase Official Docs: Manage Users in Firebase (https://firebase.google.com/docs/auth/ios/manage-users)
- Firebase Official Docs: Firestore Best Practices (https://firebase.google.com/docs/firestore/best-practices)
- Firebase Official Docs: Secure Data with Security Rules (https://firebase.google.com/docs/firestore/security/secure-data)
- Firebase Official Docs: Insecure Rules Patterns (https://firebase.google.com/docs/firestore/security/insecure-rules)
- Firebase Official Docs: Firestore Offline Persistence (https://firebase.google.com/docs/firestore/manage-data/enable-offline)
- Codebase analysis: DataService.swift, DashboardViewModel.swift, TransactionViewModel.swift, SettingsViewModel.swift, ExpenseTrackerAppApp.swift
- PROJECT.md milestone context: protocol-first approach, 80% coverage target, registration fields (Name, Gender, Phone)

---
*Pitfalls research for: Firebase Auth + Firestore iOS migration*
*Researched: 2026-04-05*

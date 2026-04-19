---
name: firebase-integration
description: Set up and integrate Firebase Authentication, Firestore, and Storage in SwiftUI iOS apps. Use when adding login/register/logout, migrating data to Firestore, configuring Firebase SDK via SPM, or implementing per-user data persistence.
---

# Firebase Integration Skill

## Operating Rules

- Always use Firebase SDK via Swift Package Manager (SPM) — no CocoaPods
- Use `@MainActor` on all ViewModel methods that update UI state after async Firebase calls
- Wrap Firebase dependencies behind protocols for testability (protocol-based DI)
- Never commit `GoogleService-Info.plist` to version control — add to `.gitignore`
- Use Firebase SDK v11+ (latest stable) for iOS 18.5+ compatibility
- Prefer async/await over completion handlers for all Firebase operations
- Handle all Firebase errors explicitly — never silently swallow them

## Task Workflow

### Set up Firebase in an Xcode project

1. Guide user through Firebase Console project creation
2. Add `GoogleService-Info.plist` to the Xcode project (non-committed)
3. Add Firebase SPM packages:
   - `FirebaseAuth` — Authentication
   - `FirebaseFirestore` — Cloud Firestore
   - `FirebaseCore` — Core SDK (required)
4. Initialize Firebase in `App` entry point:
   ```swift
   import FirebaseCore
   // In init() or AppDelegate
   FirebaseApp.configure()
   ```
5. Verify build compiles with no errors

### Implement Firebase Authentication

1. **Define protocol** for auth service:
   ```swift
   protocol AuthServiceProtocol {
       var currentUser: User? { get }
       var authState: AuthState { get }
       func signIn(email: String, password: String) async throws -> User
       func signUp(email: String, password: String) async throws -> User
       func signOut() throws
   }
   ```
2. **Create concrete implementation** wrapping `Auth.auth()`
3. **Build Auth ViewModel** with `@Published` auth state
4. **Create Login/Register views** as SwiftUI forms
5. **Add auth state listener** using `Auth.auth().addStateDidChangeListener`
6. **Handle errors**: map `AuthErrorCode` to user-friendly messages

### Migrate data to Firestore

1. **Define protocol** for data service:
   ```swift
   protocol FirestoreServiceProtocol {
       func fetchTransactions(userId: String) async throws -> [Transaction]
       func addTransaction(_ transaction: Transaction, userId: String) async throws
       func updateTransaction(_ transaction: Transaction, userId: String) async throws
       func deleteTransaction(id: UUID, userId: String) async throws
   }
   ```
2. **Design Firestore schema**:
   - Collection: `users/{userId}/transactions`
   - Document fields mirror `Transaction` struct with `Codable`
3. **Add Codable conformance** to models (already exists in this project)
4. **Implement CRUD** using `Firestore.firestore().collection().document()`
5. **Add real-time listeners** with `addSnapshotListener` for live updates
6. **Implement offline persistence** — Firestore handles this automatically when enabled

### Add security rules

- Users can only read/write their own data: `request.auth != null && request.auth.uid == userId`
- Validate document structure in rules
- Never trust client-side data without server validation

## Patterns

### Protocol-Based Service Injection

```swift
// In App entry point — use real services
@StateObject var authViewModel = AuthViewModel(authService: FirebaseAuthService())

// In tests — use mock services
@StateObject var authViewModel = AuthViewModel(authService: MockAuthService())
```

### Async Firestore CRUD

```swift
func addTransaction(_ transaction: Transaction, userId: String) async throws {
    let document = db.collection("users").document(userId)
        .collection("transactions").document(transaction.id.uuidString)
    try document.setData(from: transaction)
}
```

### Error Handling

```swift
do {
    try await authService.signUp(email: email, password: password)
} catch let error as AuthErrorCode {
    // Map AuthErrorCode to user-friendly message
    errorMessage = authErrorDescription(error)
} catch {
    errorMessage = "An unexpected error occurred."
}
```

## Checklist

Before completing a Firebase integration task:

- [ ] `GoogleService-Info.plist` is in `.gitignore`
- [ ] Firebase initialized in `App.init()` or `AppDelegate`
- [ ] All Firebase operations wrapped in protocol for testability
- [ ] ViewModels are `@MainActor` with `@Published` error/loading state
- [ ] Auth state listener properly cleans up (store `AuthStateDidChangeListenerHandle`)
- [ ] Firestore queries use `userId` scoping (per-user collections)
- [ ] Security rules configured in Firebase Console
- [ ] Offline persistence considered (Firestore default is enabled)
- [ ] Build succeeds with `xcodebuild -scheme ... -destination '...'`

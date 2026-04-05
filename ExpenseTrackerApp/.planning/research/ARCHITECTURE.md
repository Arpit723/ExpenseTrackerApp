# Architecture Research

**Domain:** SwiftUI iOS expense tracker with Firebase Auth + Firestore migration
**Researched:** 2026-04-05
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌──────────────────────────────────────────────────────────────────┐
│                        Views (SwiftUI)                           │
├──────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐ ┌──────────────┐ ┌──────────┐ ┌────────────┐  │
│  │ AuthGateView │ │ DashboardView│ │TransView │ │SettingsView│  │
│  └──────┬───────┘ └──────┬───────┘ └────┬─────┘ └─────┬──────┘  │
│         │                │              │              │          │
│  ┌──────┴───────┐ ┌──────┴───────┐ ┌────┴─────┐ ┌────┴──────┐  │
│  │ AuthViewModel│ │DashboardVM   │ │TransVM   │ │SettingsVM │  │
│  └──────┬───────┘ └──────┬───────┘ └────┬─────┘ └─────┬─────┘  │
├─────────┴────────────────┴──────────────┴──────────────┴────────┤
│                   Protocol Layer (Abstractions)                  │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐ │
│  │ AuthServiceProtocol  │  │ DataServiceProtocol              │ │
│  └──────────┬───────────┘  └──────────────┬───────────────────┘ │
├─────────────┴──────────────────────────────┴────────────────────┤
│                     Service Layer (Implementations)              │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐ │
│  │ FirebaseAuthService  │  │ FirestoreDataService             │ │
│  │                      │  │ (production)                     │ │
│  └──────────┬───────────┘  └──────────────┬───────────────────┘ │
│             │                              │                     │
├─────────────┴──────────────────────────────┴────────────────────┤
│                        Firebase SDK                              │
│  ┌──────────────────────┐  ┌──────────────────────────────────┐ │
│  │ Firebase Auth        │  │ Cloud Firestore                  │ │
│  └──────────────────────┘  └──────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘

Testing Layer (parallel):
┌──────────────────────────────────────────────────────────────────┐
│  ┌──────────────────┐  ┌──────────────────────────────────────┐ │
│  │ MockAuthService   │  │ MockDataService (in-memory)         │ │
│  └──────────────────┘  └──────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| **AuthServiceProtocol** | Abstraction for auth operations: signIn, signUp, signOut, currentUser, auth state listener | Protocol with async throws methods |
| **DataServiceProtocol** | Abstraction for data CRUD: transactions, categories, profile, computed totals | Protocol mirroring current DataService public API |
| **FirebaseAuthService** | Production auth via Firebase Auth SDK | Conforms to AuthServiceProtocol; wraps `Auth.auth()` |
| **FirestoreDataService** | Production data via Firestore, scoped per user UID | Conforms to DataServiceProtocol; reads/writes `users/{uid}/transactions` |
| **MockAuthService** | Deterministic auth for unit tests | Conforms to AuthServiceProtocol; in-memory user state |
| **MockDataService** | Deterministic data for unit tests | Conforms to DataServiceProtocol; in-memory arrays (like current DataService) |
| **AuthViewModel** | Login/register UI state, form validation, auth state observation | `@MainActor ObservableObject`; depends on AuthServiceProtocol |
| **AuthGateView** | Root-level auth gate: shows login or main app | Conditional view based on auth state |
| **DashboardViewModel** | Balance, income, expenses, recent transactions (unchanged logic) | Now depends on DataServiceProtocol instead of concrete DataService |
| **TransactionViewModel** | Filtering, sorting, search, CRUD delegation (unchanged logic) | Now depends on DataServiceProtocol |
| **SettingsViewModel** | Currency/theme management (unchanged logic) | Now depends on DataServiceProtocol |

## Recommended Project Structure

```
ExpenseTrackerApp/
├── ExpenseTrackerAppApp.swift           # @main — DI container, injects real/mock services
├── Protocols/                           # Abstraction layer (write first)
│   ├── AuthServiceProtocol.swift        # Auth contract
│   └── DataServiceProtocol.swift        # Data contract
├── Models/                              # Existing (already Codable)
│   ├── Transaction.swift
│   ├── Category.swift
│   └── UserProfile.swift               # Extend with name, gender, phone
├── Services/                            # Implementations (write after protocols)
│   ├── FirebaseAuthService.swift        # Firebase Auth wrapper
│   ├── FirestoreDataService.swift       # Firestore data layer
│   └── DataService.swift               # Keep as MockDataService or remove
├── ViewModels/                          # Refactor init to accept protocols
│   ├── AuthViewModel.swift             # NEW — auth state management
│   ├── DashboardViewModel.swift        # Modify: DataService -> DataServiceProtocol
│   ├── TransactionViewModel.swift      # Modify: DataService -> DataServiceProtocol
│   └── SettingsViewModel.swift         # Modify: DataService -> DataServiceProtocol
├── Views/
│   ├── Auth/                           # NEW — authentication screens
│   │   ├── AuthGateView.swift          # Root auth gate
│   │   ├── LoginView.swift             # Email/password login form
│   │   └── RegisterView.swift          # Registration form (name, gender, phone, email, password)
│   ├── MainTabView.swift               # Wrapped inside AuthGateView
│   ├── Dashboard/DashboardView.swift
│   ├── Transactions/
│   │   ├── TransactionsView.swift
│   │   └── AddTransactionView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift          # Add logout button
│   │   ├── CurrencyPickerView.swift
│   │   └── ThemeSelectionView.swift
│   └── Components/
│       ├── CategoryPickerGrid.swift
│       ├── TransactionRow.swift
│       └── QuickActionButton.swift
├── Utils/
│   ├── Constants.swift                 # Add auth-related notification names
│   └── Extensions/
│       ├── Color+Theme.swift
│       ├── Date+Extensions.swift
│       └── Double+Currency.swift
└── Tests/                              # Unit test targets
    ├── ViewModelTests/
    │   ├── AuthViewModelTests.swift
    │   ├── DashboardViewModelTests.swift
    │   ├── TransactionViewModelTests.swift
    │   └── SettingsViewModelTests.swift
    ├── ServiceTests/
    │   ├── MockDataServiceTests.swift
    │   └── MockAuthServiceTests.swift
    └── Mocks/
        ├── MockDataService.swift        # Protocol mock for tests
        └── MockAuthService.swift        # Protocol mock for tests
```

### Structure Rationale

- **Protocols/** as its own folder: protocols are the contract that both production and test code depend on. Separating them makes the abstraction boundary explicit and prevents accidental imports of Firebase SDK in tests.
- **Services/** contains implementations only: FirebaseAuthService and FirestoreDataService import Firebase SDK. Tests never touch this folder.
- **Views/Auth/** as a new group: auth screens are a self-contained feature with its own ViewModel, separate from the existing tab-based flow.
- **Tests/Mocks/** separated from test files: mocks are shared infrastructure used across multiple test files, not test cases themselves.

## Architectural Patterns

### Pattern 1: Protocol-Based Dependency Injection

**What:** Define protocols for services, inject concrete implementations via initializer parameters. ViewModels depend on abstractions, not implementations.

**When to use:** Always. This is the foundational pattern that enables both testability and the Firebase migration.

**Trade-offs:**
- Pro: Unit tests use mocks without Firebase SDK
- Pro: Can swap Firestore for another backend without touching ViewModels
- Pro: ViewModels become pure logic, easy to reason about
- Con: More files (protocol + implementation + mock per service)
- Con: Slight indirection when debugging

**Example:**

```swift
// Protocols/DataServiceProtocol.swift
protocol DataServiceProtocol: ObservableObject {
    var transactions: [Transaction] { get }
    var categories: [Category] { get }
    var userProfile: UserProfile? { get set }
    var totalBalance: Double { get }
    var totalIncomeThisMonth: Double { get }
    var totalExpensesThisMonth: Double { get }

    func addTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func deleteTransaction(_ transaction: Transaction)
    func category(for id: UUID) -> Category?
    func loadData()
}

// ViewModels/DashboardViewModel.swift (refactored)
@MainActor
class DashboardViewModel: ObservableObject {
    private let dataService: any DataServiceProtocol

    init(dataService: any DataServiceProtocol) {
        self.dataService = dataService
        setupBindings()
        refreshData()
    }
    // ... rest unchanged
}

// ExpenseTrackerAppApp.swift (production)
@main
struct ExpenseTrackerAppApp: App {
    @StateObject private var dataService: FirestoreDataService
    @StateObject private var authService: FirebaseAuthService

    init() {
        let auth = FirebaseAuthService()
        _authService = StateObject(wrappedValue: auth)
        _dataService = StateObject(wrappedValue: FirestoreDataService(authService: auth))
    }
    // ...
}
```

### Pattern 2: Auth State Observation via Combine/Async

**What:** FirebaseAuthService publishes auth state changes. AuthGateView observes this and conditionally renders login screens or the main app. ViewModels that need user context access it through the auth service.

**When to use:** For any app with authentication. The auth state is the root decision point for the entire view hierarchy.

**Trade-offs:**
- Pro: Single source of truth for auth state
- Pro: Automatic UI transitions when user signs in/out
- Pro: No manual state management in individual views
- Con: Need to handle the "loading" state during Firebase's initial auth check

**Example:**

```swift
// Protocols/AuthServiceProtocol.swift
enum AuthState {
    case loading       // Firebase checking stored session
    case unauthenticated
    case authenticated(User)
}

protocol AuthServiceProtocol: ObservableObject {
    var authState: AuthState { get }
    var currentUser: User? { get }

    func signIn(email: String, password: String) async throws
    func signUp(name: String, gender: String, phone: String, email: String, password: String) async throws
    func signOut() throws
}

// Services/FirebaseAuthService.swift
@MainActor
class FirebaseAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .loading
    @Published var currentUser: User?
    private var handle: AuthStateDidChangeListenerHandle?

    init() {
        listenForAuthChanges()
    }

    private func listenForAuthChanges() {
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }
            if let firebaseUser {
                let user = User(uid: firebaseUser.uid, email: firebaseUser.email ?? "")
                self.currentUser = user
                self.authState = .authenticated(user)
            } else {
                self.currentUser = nil
                self.authState = .unauthenticated
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        // authState listener handles the rest
    }

    func signUp(name: String, gender: String, phone: String, email: String, password: String) async throws {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        // Store profile in Firestore
        try await Firestore.firestore()
            .collection("users").document(result.user.uid)
            .setData(["name": name, "gender": gender, "phone": phone, "email": email])
    }

    func signOut() throws {
        try Auth.auth().signOut()
        // authState listener handles the rest
    }

    deinit {
        if let handle { Auth.auth().removeStateDidChangeListener(handle) }
    }
}

// Views/Auth/AuthGateView.swift
struct AuthGateView: View {
    @StateObject private var authService: FirebaseAuthService
    @StateObject private var dataService: FirestoreDataService

    init(authService: FirebaseAuthService, dataService: FirestoreDataService) {
        _authService = StateObject(wrappedValue: authService)
        _dataService = StateObject(wrappedValue: dataService)
    }

    var body: some View {
        switch authService.authState {
        case .loading:
            ProgressView("Loading...")
        case .unauthenticated:
            AuthView(authService: authService)
        case .authenticated:
            MainTabView()
                .environmentObject(dataService)
                .environmentObject(authService)
        }
    }
}
```

### Pattern 3: Firestore Repository with Per-User Scoping

**What:** FirestoreDataService loads data only for the authenticated user's UID. All Firestore paths are prefixed with `users/{uid}/`. Data is loaded on auth state change and cleared on sign-out.

**When to use:** Any multi-user Firestore app. Per-user subcollections prevent cross-user data access and simplify security rules.

**Trade-offs:**
- Pro: Clean security rules: `allow read, write: if request.auth.uid == resource.data.uid`
- Pro: Queries are naturally scoped -- no accidental cross-user data
- Pro: Easy to delete all user data (delete user document + subcollections)
- Con: Two approaches exist (subcollections vs root collections with uid field); subcollections are cleaner for this use case
- Con: Firestore listener management requires careful cleanup to avoid memory leaks

**Example:**

```swift
// Services/FirestoreDataService.swift
@MainActor
class FirestoreDataService: ObservableObject, DataServiceProtocol {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var userProfile: UserProfile?

    private let db = Firestore.firestore()
    private let authService: any AuthServiceProtocol
    private var transactionsListener: ListenerRegistration?
    private var profileListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()

    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        setupAuthObserver()
    }

    private func setupAuthObserver() {
        // When auth state changes, attach/detach Firestore listeners
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .authenticated(let user):
                    self?.attachListeners(for: user.uid)
                case .unauthenticated, .loading:
                    self?.detachListeners()
                    self?.clearLocalData()
                }
            }
            .store(in: &cancellables)
    }

    private func transactionsPath(_ uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("transactions")
    }

    private func profilePath(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }

    private func attachListeners(for uid: String) {
        // Seed default categories for new users
        seedCategoriesIfNeeded(uid: uid)

        // Real-time listener for transactions
        transactionsListener = transactionsPath(uid)
            .order(by: "date", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let docs = snapshot?.documents else { return }
                self?.transactions = docs.compactMap { try? $0.data(as: Transaction.self) }
                NotificationCenter.default.post(name: .transactionDataChanged, object: nil)
            }

        // Real-time listener for profile
        profileListener = profilePath(uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let data = snapshot?.data() else { return }
                self?.userProfile = try? Firestore.Decoder().decode(UserProfile.self, from: data)
            }
    }

    func addTransaction(_ transaction: Transaction) {
        guard let uid = authService.currentUser?.uid else { return }
        do {
            try transactionsPath(uid).document(transaction.id.uuidString).setData(from: transaction)
        } catch {
            // Post error notification for ViewModel to handle
            NotificationCenter.default.post(name: .dataServiceError, object: error)
        }
    }

    // ... updateTransaction, deleteTransaction follow same pattern

    private func detachListeners() {
        transactionsListener?.remove()
        profileListener?.remove()
        transactionsListener = nil
        profileListener = nil
    }
}
```

### Pattern 4: Notification-Based Cross-ViewModel Communication (Refined)

**What:** The existing NotificationCenter pattern for cross-ViewModel updates continues, but the trigger shifts. Instead of DataService posting after local array mutation, FirestoreDataService's snapshot listeners post notifications when Firestore confirms the write.

**When to use:** When multiple ViewModels need to react to the same data change without coupling to each other.

**Trade-offs:**
- Pro: Minimal refactoring of existing ViewModel code
- Pro: ViewModels remain decoupled from each other
- Pro: Works identically in production (Firestore) and tests (MockDataService posts directly)
- Con: NotificationCenter is stringly-typed and hard to debug in large apps
- Con: Not needed long-term if moving to a single reactive data source

**Refinement:** Add a new notification name for the Firestore-era cross-ViewModel communication.

```swift
// Utils/Constants.swift — add to existing notification names
extension Notification.Name {
    // Keep existing for backward compat during migration
    static let transactionAdded = Notification.Name("transactionAdded")
    static let transactionUpdated = Notification.Name("transactionUpdated")
    static let transactionDeleted = Notification.Name("transactionDeleted")

    // New: generic "data changed" for Firestore listener-driven updates
    static let transactionDataChanged = Notification.Name("transactionDataChanged")
    static let dataServiceError = Notification.Name("dataServiceError")
}
```

## Data Flow

### Auth Flow (Registration)

```
[User fills form]
    |
    v
RegisterView --> AuthViewModel.signUp()
    |                |
    |                v
    |         authService.signUp(name, gender, phone, email, password)
    |                |
    |                v
    |         [FirebaseAuthServiceImpl]
    |                |
    |                +---> Auth.auth().createUser(withEmail:password:)
    |                |         |
    |                |         v
    |                |    Firebase returns AuthResult
    |                |         |
    |                |         v
    |                +---> Firestore: set profile doc at users/{uid}
    |                |         |
    |                |         v
    |                +---> AuthState listener fires
    |                          |
    v                          v
AuthGateView observes .authenticated --> renders MainTabView
                                              |
                                              v
                                    FirestoreDataService attaches
                                    listeners for user's data
```

### Auth Flow (Login)

```
[User enters email/password]
    |
    v
LoginView --> AuthViewModel.signIn()
    |              |
    |              v
    |       authService.signIn(email, password)
    |              |
    |              v
    |       Auth.auth().signIn(withEmail:password:)
    |              |
    |              v
    |       AuthState listener fires --> .authenticated(user)
    |
    v
AuthGateView renders MainTabView --> FirestoreDataService loads user data
```

### Transaction CRUD Flow (Production)

```
[User taps Add/Save]
    |
    v
AddTransactionView --> TransactionViewModel.addTransaction()
    |                        |
    |                        v
    |                 dataService.addTransaction(transaction)
    |                        |
    |                        v
    |                 [FirestoreDataService]
    |                        |
    |                        v
    |                 Firestore: setData at users/{uid}/transactions/{id}
    |                        |
    |                        v
    |                 Snapshot listener fires --> @Published transactions updated
    |                        |
    |                        v
    |                 NotificationCenter: .transactionDataChanged
    |
    v
DashboardViewModel receives notification --> refreshData()
    |
    v
TransactionViewModel's transactions already updated via snapshot listener
```

### State Management

```
Auth State (single source of truth):
    FirebaseAuthService.authState: AuthState
        |
        +---> AuthGateView (conditional rendering)
        +---> FirestoreDataService (attach/detach listeners)
        +---> ViewModels (via authService.currentUser for uid)

Data State (per-service):
    FirestoreDataService.transactions: [Transaction]  <-- Firestore snapshot listener
    FirestoreDataService.categories: [Category]       <-- Firestore snapshot listener
    FirestoreDataService.userProfile: UserProfile?     <-- Firestore snapshot listener

View State (per-ViewModel):
    DashboardViewModel.totalBalance: Double            <-- computed from dataService
    TransactionViewModel.filteredTransactions: [Trans]  <-- computed + filter pipeline
    AuthViewModel.isLoading / errorMessage              <-- UI-only state

Persistence:
    @AppStorage: currency, theme (device-local, not Firestore)
    UserDefaults: stays as-is (not user-scoped, acceptable for v1)
    Firestore: transactions, categories, profile (cloud, user-scoped)
```

## Build Order (Suggested Phase Sequence)

The build order follows dependency chains. Each phase produces testable, shippable code.

```
Phase 1: Protocol Extraction (zero new dependencies)
    |
    |  Extract DataServiceProtocol from DataService
    |  Make existing DataService conform to DataServiceProtocol
    |  Refactor ViewModels to depend on protocol
    |  Create MockDataService for tests
    |  Write ViewModel unit tests with mocks
    |
    v
Phase 2: Auth Protocol + Auth Views (no Firebase yet)
    |
    |  Define AuthServiceProtocol
    |  Create MockAuthService
    |  Build AuthViewModel, LoginView, RegisterView, AuthGateView
    |  AuthGateView uses MockAuthService (switches between auth/unauth states)
    |  Write AuthViewModel unit tests
    |
    v
Phase 3: Firebase SDK Integration (SPM + Firebase setup)
    |
    |  Add Firebase SDK via SPM
    |  Configure FirebaseApp in app entry point
    |  Implement FirebaseAuthService (conforms to AuthServiceProtocol)
    |  Wire FirebaseAuthService into app
    |  Manual testing: register, login, logout works
    |
    v
Phase 4: Firestore Data Layer
    |
    |  Implement FirestoreDataService (conforms to DataServiceProtocol)
    |  Per-user scoping: users/{uid}/transactions, users/{uid}/profile
    |  Firestore snapshot listeners for real-time sync
    |  Seed default categories for new users
    |  Extend UserProfile with registration fields (name, gender, phone)
    |  Wire FirestoreDataService into app (replace in-memory DataService)
    |  Manual testing: transactions persist across sessions
    |
    v
Phase 5: Testing + Polish
    |
    |  Integration test: full register -> add transaction -> sign out -> sign in -> verify
    |  Error handling: network failures, auth errors, Firestore errors
    |  Edge cases: offline mode, concurrent edits
    |  80% code coverage target on ViewModels and Services
```

### Dependency Rationale

- **Protocols before Firebase**: Protocols enable testing without the Firebase SDK. Once protocols exist, Firebase becomes just another implementation. This is the most critical ordering decision.
- **Auth views before Firebase Auth**: Building the auth UI with a mock service lets you iterate on UX without waiting for Firebase configuration (GoogleService-Info.plist, Firebase console setup).
- **Firebase Auth before Firestore**: Firestore paths require a user UID. Auth must work first.
- **Firestore last**: The data layer is the riskiest change. Having all tests in place before touching Firestore means you can verify nothing broke.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| Single user (MVP) | Current architecture is perfect. Firestore free tier (50K reads/day, 20K writes/day) handles this easily. |
| 100-1000 users | No changes needed. Firestore auto-scales. Add Firestore composite indexes if query performance degrades. |
| 10K+ users | Consider pagination for transaction list (currently loads all). Add batched writes for category seeding. Monitor Firestore read volume. |
| 100K+ users | Not in scope. Would need offline persistence strategy, batch data export, and likely a Cloud Function for aggregation. |

### Scaling Priorities

1. **First bottleneck: Transaction list loading** -- currently fetches all user transactions. At 1000+ transactions per user, add Firestore query limits with pagination (`.limit(to: 50)` with cursor-based pagination).
2. **Second bottleneck: Monthly aggregation queries** -- `totalIncomeThisMonth` and `totalExpensesThisMonth` are computed client-side from all transactions. If transaction count grows, pre-compute these in a Cloud Function or store monthly summaries.

## Anti-Patterns

### Anti-Pattern 1: Importing Firebase SDK in ViewModels or View Files

**What people do:** Use `import Firebase` directly in ViewModel or View files.
**Why it is wrong:** Creates hard coupling to Firebase. Makes unit testing impossible without Firebase SDK in test target. Defeats the purpose of protocol-based DI.
**Do this instead:** Firebase imports only in `FirebaseAuthService.swift` and `FirestoreDataService.swift`. ViewModels depend on protocols. Views depend on ViewModels.

### Anti-Pattern 2: Storing Transactions Under a Root Collection

**What people do:** Create a top-level `transactions` collection with a `userId` field, then filter queries by userId.
**Why it is wrong:** More complex security rules. Higher risk of accidental cross-user data exposure. Harder to manage per-user data lifecycle (deletion, export).
**Do this instead:** Use subcollections: `users/{uid}/transactions`. Security rule becomes trivial: `allow read, write: if request.auth != null && request.auth.uid == resource.name.split('/')[1]`. Data is naturally scoped.

### Anti-Pattern 3: Using Firestore Auto-Generated Document IDs Instead of Model UUIDs

**What people do:** Let Firestore generate document IDs with `addDocument()` and then try to map them back to model IDs.
**Why it is wrong:** The existing models use `UUID` identifiers. Views reference transactions by UUID. Firestore auto-IDs are strings, not UUIDs, creating a type mismatch and requiring conversion logic.
**Do this instead:** Use the model's UUID as the Firestore document ID: `collection.document(transaction.id.uuidString).setData(from: transaction)`. This preserves the existing ID scheme and makes Firestore document paths predictable.

### Anti-Pattern 4: Skipping the "Loading" Auth State

**What people do:** Start with `authState = .unauthenticated` and transition to `.authenticated` when Firebase returns a user.
**Why it is wrong:** Firebase Auth checks for a stored session asynchronously on app launch. During this check (which can take 100-500ms), the user is momentarily unauthenticated. Starting with `.unauthenticated` causes a flash of the login screen before resolving to `.authenticated`.
**Do this instead:** Start with `authState = .loading`. Show a splash/loading screen. Only transition to `.unauthenticated` or `.authenticated` after Firebase's `addStateDidChangeListener` fires its first callback.

### Anti-Pattern 5: Using @AppStorage for User-Scoped Settings

**What people do:** Continue using `@AppStorage` (UserDefaults) for currency and theme after adding auth.
**Why it is wrong:** UserDefaults is device-local, not user-scoped. If two users share one device, they see each other's currency/theme. If one user has two devices, settings do not sync.
**Do this instead (for this project):** Accept this limitation for v1. The project scope says "single currency per user" and the migration to Firestore settings is explicitly out of scope. Document this as known limitation. If needed later, move preferences to the Firestore profile document.

### Anti-Pattern 6: Forgetting to Detach Firestore Listeners on Sign-Out

**What people do:** Attach snapshot listeners on sign-in but forget to remove them on sign-out.
**Why it is wrong:** Listeners continue firing for the old user's data. Memory leak. Potential cross-user data display if the listener callback updates `@Published` properties after a new user signs in.
**Do this instead:** Always pair `addSnapshotListener` with `remove()` in a `detachListeners()` method. Call it when auth state transitions to `.unauthenticated`.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Firebase Auth | Direct SDK usage via `Auth.auth()` | Use `addStateDidChangeListener` for automatic session persistence. Do not manually store tokens. |
| Cloud Firestore | Direct SDK usage via `Firestore.firestore()` | Use `addSnapshotListener` for real-time updates. Use `setData(from:)` with Codable for type-safe writes. |
| Firebase iOS SDK | Swift Package Manager via Xcode | Add `firebase-ios-sdk` package. Only include `FirebaseAuth` and `FirebaseFirestore` products to minimize binary size. |
| GoogleService-Info.plist | File in app bundle, downloaded from Firebase Console | Required by Firebase SDK at runtime. Add to `.gitignore` for security -- each developer needs their own. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Views to ViewModels | `@StateObject` observation | Views own ViewModels, observe `@Published` properties |
| ViewModels to Services | Protocol method calls (sync or async) | ViewModels call protocol methods. Production implementations may be async (Firebase), mock implementations are synchronous. |
| AuthViewModel to AuthServiceProtocol | Async throws method calls | `signIn`, `signUp` are async because Firebase network calls are async. Mock returns immediately. |
| FirestoreDataService to AuthServiceProtocol | Property access + Combine publisher | DataService reads `authService.currentUser?.uid` for Firestore paths. Observes `$authState` to attach/detach listeners. |
| Cross-ViewModel | NotificationCenter | Existing pattern. `.transactionDataChanged` for Firestore-driven updates. Keep `.transactionAdded/Updated/Deleted` for MockDataService. |
| Settings to Storage | `@AppStorage` (UserDefaults) | Unchanged. Device-local, not user-scoped. Acceptable for v1. |

### Firestore Data Model

```
users/                              (collection)
  {uid}/                            (document — UID from Firebase Auth)
    profile fields:                  (stored directly on user document)
      name: String
      gender: String
      phone: String
      email: String
      currency: String
      theme: String
      createdAt: Timestamp
      updatedAt: Timestamp
    transactions/                    (subcollection)
      {uuid}/                        (document — UUID from Transaction model)
        id: String (UUID string)
        amount: Double
        categoryId: String (UUID string)
        date: Timestamp
        payee: String?
        notes: String?
        createdAt: Timestamp
        updatedAt: Timestamp
    categories/                      (subcollection)
      {uuid}/                        (document — UUID from Category model)
        id: String (UUID string)
        name: String
        icon: String (SF Symbol name)
        color: String (hex)
        isSystem: Bool
        createdAt: Timestamp
        updatedAt: Timestamp
```

**Why this structure:**
- User document at root: simple `setData` for profile, single document read for user info
- Transactions as subcollection: naturally scoped per user, queryable, paginated
- Categories as subcollection: allows future per-user custom categories
- Document IDs use model UUIDs: preserves existing ID scheme, no ID mapping

**Firestore Security Rules (recommended):**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
      match /categories/{categoryId} {
        allow read, write: if request.auth != null && request.auth.uid == uid;
      }
    }
  }
}
```

## Key Technical Decisions

### Why `ObservableObject` instead of `@Observable` (Swift 5.9 Observation framework)

The project uses `ObservableObject` throughout. Switching to `@Observable` would require rewriting all ViewModels and changing how views observe them (`@State` instead of `@StateObject`). The iOS 18.5+ target supports `@Observable`, but the existing codebase is deeply invested in `ObservableObject`. The migration to `@Observable` is orthogonal to the Firebase migration and would add unnecessary scope. Stick with `ObservableObject` for this milestone.

### Why Categories as Firestore Subcollection (not hardcoded in client)

The current `Category.defaultCategories` is hardcoded in the client. Moving categories to Firestore has two benefits:
1. Categories are user-scoped (future: custom categories per user)
2. Category state is part of the data layer, making mock/testing cleaner

The seed operation (writing default categories for new users) happens once during sign-up. After that, categories are read from Firestore like any other data.

### Why `async/await` for Auth Methods (not completion handlers)

Firebase Auth SDK supports async/await natively on iOS 18.5+. The API is cleaner than completion handlers. ViewModels call `await authService.signIn(...)` in async contexts. Error handling uses standard `do/catch`. No Combine needed for auth calls.

### Why Combine for Auth State Observation (not async stream)

`AuthServiceProtocol` conforms to `ObservableObject` with `@Published authState`. This lets AuthGateView use SwiftUI's built-in `@StateObject` observation. Using Combine's `$authState` publisher for FirestoreDataService to observe is consistent with the existing pattern. An async stream would require a different observation mechanism in views.

## Sources

- Firebase Auth Swift documentation: https://firebase.google.com/docs/auth/ios/start
- Firestore Swift documentation: https://firebase.google.com/docs/firestore/quickstart
- Firestore data modeling (subcollections): https://firebase.google.com/docs/firestore/manage-data/structure-data
- Firestore security rules: https://firebase.google.com/docs/firestore/security/get-started
- Firebase iOS SDK SPM installation: https://firebase.google.com/docs/ios/setup
- Existing codebase analysis: `Services/DataService.swift`, `ViewModels/*.swift`, `Models/*.swift`, `ExpenseTrackerAppApp.swift`
- Codebase architecture documentation: `.planning/codebase/ARCHITECTURE.md`
- Project requirements: `.planning/PROJECT.md`

---
*Architecture research for: SwiftUI expense tracker with Firebase Auth + Firestore*
*Researched: 2026-04-05*

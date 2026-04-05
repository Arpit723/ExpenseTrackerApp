# Phase 1: Protocol Extraction - Research

**Researched:** 2026-04-05
**Domain:** Swift protocol-oriented design, MVVM dependency injection, SwiftUI service abstraction
**Confidence:** HIGH

## Summary

This phase extracts protocol abstractions from the existing concrete `DataService` and defines a new `AuthServiceProtocol`, enabling all ViewModels to depend on protocols rather than concrete types. The current codebase already uses init-based dependency injection with default parameters (`init(dataService: DataService = .shared)`), making the type generalization straightforward -- change the concrete type to `any DataServiceProtocol` and add protocol conformance to `DataService`.

The critical path is: (1) define `DataServiceProtocol` mirroring all public members of `DataService`, (2) define `AuthServiceProtocol` for future auth, (3) change ViewModel property types from `DataService` to `any DataServiceProtocol`, (4) make `DataService` conform to the protocol, (5) create `MockDataService` and `MockAuthService` in the test target. No behavior changes -- purely structural refactoring.

**Primary recommendation:** Define protocols in a new `Protocols/` directory, use `any DataServiceProtocol` (not `some`) for ViewModel stored properties to allow test-time swapping, and annotate protocols with `@MainActor` to match the existing ViewModel isolation pattern.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** One protocol per service -- `DataServiceProtocol` and `AuthServiceProtocol` (no interface segregation)
- **D-02:** DataServiceProtocol mirrors all public API of the current DataService: CRUD operations, computed properties (totalBalance, totalIncomeThisMonth, totalExpensesThisMonth), helper methods (category(for:), groupedTransactions()), and Published-wrapping accessors
- **D-03:** AuthServiceProtocol declares: register(email:password:name:gender:phone:completion:), login(email:password:completion:), logout(completion:), addAuthStateListener(_:), removeAuthStateListener()
- **D-04:** AuthState enum with three cases: loading, authenticated, unauthenticated -- published by any AuthServiceProtocol conformance
- **D-05:** All ViewModels change their `dataService` property type from `DataService` to `any DataServiceProtocol`
- **D-06:** ViewModels init signature changes from `init(dataService: DataService = .shared)` to `init(dataService: any DataServiceProtocol = DataService.shared)`
- **D-07:** Existing DataService conforms to DataServiceProtocol
- **D-08:** App entry point continues to use DataService.shared -- no changes to production wiring yet
- **D-09:** MockDataService conforming to DataServiceProtocol -- stores data in-memory arrays (like current DataService), supports all CRUD and computed properties
- **D-10:** MockAuthService conforming to AuthServiceProtocol -- simulates auth state with configurable behavior (auto-succeed, auto-fail, delay)
- **D-11:** Mocks placed in test target (not main app target) since they're only needed for testing
- **D-12:** Notification posting stays in DataService (concrete implementation detail). DataServiceProtocol does NOT declare notification posting -- it's an implementation concern, not a contract
- **D-13:** ViewModels continue listening to notifications in setupBindings() -- this is fine for now, can be replaced with direct observation in Phase 5 if needed
- **D-14:** DataServiceProtocol declares properties as `var transactions: [Transaction] { get }` (not @Published). The concrete DataService uses @Published internally but the protocol only requires getter access
- **D-15:** ViewModels that need reactive updates from data changes continue using NotificationCenter observers -- this works with any DataServiceProtocol conformance since the concrete types post notifications

### Claude's Discretion
- Exact file organization for protocols (single file per protocol, or grouped)
- Whether to use `any Protocol` or `some Protocol` in ViewModel property declarations
- Mock implementation details (how configurable, which edge cases to support)
- Whether to add documentation comments to protocol declarations

### Deferred Ideas (OUT OF SCOPE)
- None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ARCH-01 | DataServiceProtocol extracted from existing DataService with all CRUD operations and computed properties | "DataServiceProtocol Design" section below -- full protocol API mapped from DataService.swift |
| ARCH-02 | AuthServiceProtocol defined with register, login, logout, and auth state listener methods | "AuthServiceProtocol Design" section below -- API shaped per D-03/D-04 decisions |
| ARCH-03 | All ViewModels accept service protocols via init (not concrete types) for dependency injection | "ViewModel Refactoring" section below -- all 3 ViewModels analyzed, init pattern already established |
| ARCH-04 | MockDataService and MockAuthService conform to protocols for unit testing | "Mock Implementation Strategy" section below -- placement and conformance approach documented |
</phase_requirements>

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Swift | 6.1.2 | Language | Apple first-party, installed on this machine [VERIFIED: `swift --version`] |
| SwiftUI | iOS 18.5+ | UI framework | Project deployment target [VERIFIED: CLAUDE.md] |
| Combine | iOS 18.5+ | Reactive bindings | Already used for NotificationCenter subscriptions [VERIFIED: codebase grep] |
| XCTest | Xcode 16.4 | Testing | Apple first-party, test target exists [VERIFIED: test run succeeded] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Foundation | iOS 18.5+ | Base types, NotificationCenter | All files -- already imported everywhere |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Manual protocol extraction | Sourcery/Mockolo auto-generation | Overkill for 2 protocols -- manual is clearer and matches project's zero-dependency policy |
| `some Protocol` | `any Protocol` | `some` is opaque and cannot be reassigned at runtime; `any` supports test-time swapping, required for DI pattern |

**Installation:** No new packages required. This phase is pure Swift refactoring using existing frameworks.

**Version verification:**
```
Swift: 6.1.2 (swiftlang-6.1.2.1.2) [VERIFIED: swift --version]
Xcode: 16.4 (Build 16F6) [VERIFIED: xcodebuild -version]
iOS deployment target: 18.5 [VERIFIED: CLAUDE.md, STACK.md]
```

## Architecture Patterns

### Recommended Project Structure
```
ExpenseTrackerApp/
├── Protocols/                           # NEW - Protocol abstractions
│   ├── DataServiceProtocol.swift        # Data contract (mirrors DataService public API)
│   └── AuthServiceProtocol.swift        # Auth contract (new, for future Firebase)
├── Models/                              # UNCHANGED
├── Services/
│   └── DataService.swift                # MODIFIED - add DataServiceProtocol conformance
├── ViewModels/                          # MODIFIED - type changes only
├── Views/                               # MINIMAL CHANGE - #Preview blocks only
└── ...

ExpenseTrackerAppTests/                  # NEW files added here
├── ExpenseTrackerAppTests.swift         # KEEP existing
├── Mocks/                               # NEW directory for mock implementations
│   ├── MockDataService.swift            # MockDataService conforming to DataServiceProtocol
│   └── MockAuthService.swift            # MockAuthService conforming to AuthServiceProtocol
```

### Pattern 1: Protocol-First Service Abstraction
**What:** Define a protocol that declares all operations a service provides. ViewModels depend on the protocol, never the concrete type.
**When to use:** Every service that ViewModels access directly.
**Example:**
```swift
// Source: [ASSUMED] - Standard Swift protocol pattern, well-established
@MainActor
protocol DataServiceProtocol: ObservableObject {
    var transactions: [Transaction] { get }
    var categories: [Category] { get }
    var userProfile: UserProfile? { get }

    var totalBalance: Double { get }
    var totalExpensesThisMonth: Double { get }
    var totalIncomeThisMonth: Double { get }

    func loadData()
    func category(for id: UUID) -> Category?
    func groupedTransactions() -> [(String, [Transaction])]

    func addTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func deleteTransaction(_ transaction: Transaction)
}
```

**Critical design note:** The protocol extends `ObservableObject` so that conforming types (DataService, MockDataService) can be used with `@StateObject` and `@EnvironmentObject` in SwiftUI. The concrete `DataService` already conforms to `ObservableObject` via its class definition. This ensures the existing `ExpenseTrackerAppApp.swift` injection via `.environmentObject()` continues to work without changes. [ASSUMED]

### Pattern 2: `any Protocol` for Stored Properties
**What:** Use `any DataServiceProtocol` (existential type) for ViewModel stored properties, not `some DataServiceProtocol` (opaque type).
**When to use:** Any stored property that must be assignable/swappable at runtime (e.g., test injection).
**Why `any` not `some`:**
- `some` requires the concrete type to be fixed at init time and never changes -- it is opaque but singular.
- `any` allows runtime polymorphism -- the property can hold any conforming type.
- For testing, ViewModels need to accept either `DataService.shared` (production) or `MockDataService()` (tests).
- Swift 5.7+ requires explicit `any` for existential types; Swift 6 enforces this strictly.

```swift
// BEFORE (concrete type):
private let dataService: DataService
init(dataService: DataService = .shared)

// AFTER (existential protocol):
private let dataService: any DataServiceProtocol
init(dataService: any DataServiceProtocol = DataService.shared)
```
[ASSUMED] - Standard Swift 6 concurrency and generics pattern.

### Pattern 3: @MainActor Protocol Annotation
**What:** Annotate both `DataServiceProtocol` and `AuthServiceProtocol` with `@MainActor`.
**When to use:** Protocols whose conforming types are accessed from `@MainActor` ViewModels.
**Why:** All three ViewModels are `@MainActor`. If the protocol is not `@MainActor`, calling protocol methods from a `@MainActor` context requires `await` in Swift 6 strict concurrency mode. Annotating the protocol itself avoids this.

```swift
@MainActor
protocol DataServiceProtocol: ObservableObject { ... }
```
[ASSUMED] - Swift concurrency best practice, recommended for Swift 6.

### Pattern 4: AuthServiceProtocol with Completion Handlers
**What:** Auth operations use completion handler signatures matching the Firebase Auth SDK pattern.
**When to use:** Async operations that may succeed or fail.
**Why completion handlers, not async/await:** The CONTEXT.md decisions (D-03) specify completion handlers. This also matches Firebase's callback-based API, making the future FirebaseAuthService wrapper simpler.

```swift
@MainActor
protocol AuthServiceProtocol: ObservableObject {
    var authState: AuthState { get }

    func register(email: String, password: String, name: String, gender: String, phone: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    func login(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void)
    func logout(completion: @escaping (Result<Void, Error>) -> Void)
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void)
    func removeAuthStateListener()
}

enum AuthState {
    case loading
    case authenticated(UserProfile)
    case unauthenticated
}
```
[ASSUMED] - Pattern shaped by D-03/D-04 decisions.

### Anti-Patterns to Avoid

- **Declaring notification posting in the protocol:** D-12 explicitly states notifications are an implementation detail. The protocol should NOT have a `postNotification()` requirement. The concrete DataService posts notifications internally after CRUD operations. MockDataService can choose to post or not depending on test needs.
- **Using `@Published` in protocol requirements:** D-14 explicitly states protocol properties are read-only getters. The `@Published` property wrapper is a concrete implementation detail of `ObservableObject` conformances, not a protocol concern.
- **Changing the app entry point DI wiring:** D-08 states no changes to production wiring. `ExpenseTrackerAppApp.swift` continues using `@StateObject private var dataService = DataService.shared`.
- **Placing mocks in the main app target:** D-11 states mocks go in the test target only. This keeps production code clean and avoids dead code in shipping builds.
- **Changing ObservableObject inheritance:** DataService must remain `ObservableObject` for `.environmentObject()` injection. The protocol should inherit from `ObservableObject` to ensure type compatibility.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Auth state management | Custom state tracking enum from scratch | `AuthState` enum per D-04 | Simple 3-case enum, but the user already defined the contract -- follow it exactly |
| Mock service behavior | Complex configurable mock with DSL | Simple in-memory mock with canned responses | Over-engineering. Mocks just need to satisfy protocol and return predictable data for tests |

**Key insight:** This phase is primarily about extracting and declaring -- not building new functionality. The existing DataService already has a clean public API that maps directly to protocol requirements. The risk is in getting the protocol API wrong (missing a method, wrong signature), not in building complex new systems.

## Common Pitfalls

### Pitfall 1: Missing `ObservableObject` Inheritance on Protocol
**What goes wrong:** If `DataServiceProtocol` does not inherit from `ObservableObject`, then `@StateObject private var dataService = DataService.shared` in `ExpenseTrackerAppApp.swift` will fail to compile because `DataService.shared` would not be provably an `ObservableObject` through the protocol.
**Why it happens:** Forgetting that SwiftUI's `@StateObject` and `.environmentObject()` require `ObservableObject` conformance, not just any protocol.
**How to avoid:** Declare `protocol DataServiceProtocol: ObservableObject`.
**Warning signs:** Compiler error: "Cannot convert value of type 'DataService' to expected argument type 'any ObservableObject'" or similar.

### Pitfall 2: `@Published` Property Wrapper in Protocol
**What goes wrong:** Trying to write `@Published var transactions: [Transaction] { get }` in the protocol. `@Published` is a property wrapper that only works on concrete stored properties, not protocol requirements.
**Why it happens:** Copying the DataService class declarations verbatim into the protocol.
**How to avoid:** Use plain `var transactions: [Transaction] { get }` in the protocol. The concrete DataService keeps its `@Published` internally.
**Warning signs:** Compiler error: "Property wrapper 'Published' cannot be used in a protocol."

### Pitfall 3: Losing `objectWillChange` Publisher
**What goes wrong:** If the protocol does not inherit `ObservableObject`, the `objectWillChange` publisher won't be available, and SwiftUI views won't receive updates when data changes.
**Why it happens:** Treating the protocol as a plain interface without considering the `ObservableObject` contract.
**How to avoid:** `DataServiceProtocol: ObservableObject` ensures the `objectWillChange` publisher requirement is inherited.
**Warning signs:** Views compile but don't update when data changes.

### Pitfall 4: Preview Blocks Using Concrete DataService.shared
**What goes wrong:** After refactoring, `#Preview` blocks in `CategoryPickerGrid.swift` and `TransactionRow.swift` still reference `DataService.shared` directly. This works but is inconsistent with the new protocol-based pattern.
**Why it happens:** These preview blocks were not updated as part of the refactoring.
**How to avoid:** These can remain as-is since they're compile-time preview-only code. They reference the concrete type which still exists. Optionally update for consistency.
**Warning signs:** None -- this is cosmetic, not functional. The previews work either way.

### Pitfall 5: Test Target Cannot Access Protocol/Mock Types
**What goes wrong:** Adding mock files to the test target directory but not adding them to the `ExpenseTrackerAppTests` build target in the Xcode project (`project.pbxproj`).
**Why it happens:** Xcode does not automatically detect new files in the filesystem -- they must be added to the project navigator.
**How to avoid:** Plan must include explicit step to add new files to the Xcode test target via project navigator (or verify pbxproj is updated).
**Warning signs:** Compiler error in test files: "Cannot find 'MockDataService' in scope" or "Use of unresolved identifier."

### Pitfall 6: `any DataServiceProtocol` Default Parameter
**What goes wrong:** Writing `init(dataService: any DataServiceProtocol)` without a default value breaks all existing view code that creates ViewModels via `@StateObject private var viewModel = DashboardViewModel()`.
**Why it happens:** Forgetting that views rely on the default parameter to work without explicitly passing a service.
**How to avoid:** Always include the default: `init(dataService: any DataServiceProtocol = DataService.shared)`.
**Warning signs:** Compiler errors in every view that creates a ViewModel without arguments.

## Code Examples

### DataServiceProtocol -- Complete Definition
```swift
// Source: [VERIFIED: codebase analysis of DataService.swift]
// Every member maps directly to an existing public member of DataService

import Foundation
import Combine

@MainActor
protocol DataServiceProtocol: ObservableObject {
    // Published-wrapping getters (D-14)
    var transactions: [Transaction] { get }
    var categories: [Category] { get }
    var userProfile: UserProfile? { get }

    // Computed properties
    var totalBalance: Double { get }
    var totalExpensesThisMonth: Double { get }
    var totalIncomeThisMonth: Double { get }

    // Data loading
    func loadData()

    // Helper methods
    func category(for id: UUID) -> Category?
    func groupedTransactions() -> [(String, [Transaction])]

    // CRUD operations
    func addTransaction(_ transaction: Transaction)
    func updateTransaction(_ transaction: Transaction)
    func deleteTransaction(_ transaction: Transaction)
}
```

### DataService Conformance (minimal change)
```swift
// Source: [VERIFIED: existing DataService.swift]
// Only change: add protocol conformance to class declaration

class DataService: ObservableObject, DataServiceProtocol {
    // Everything else stays exactly the same
    // The protocol requirements are already implemented
    // No method bodies change
}
```

### ViewModel Refactoring (all 3 ViewModels follow same pattern)
```swift
// Source: [VERIFIED: DashboardViewModel.swift, TransactionViewModel.swift, SettingsViewModel.swift]

// BEFORE:
private let dataService: DataService
init(dataService: DataService = .shared) {
    self.dataService = dataService
}

// AFTER:
private let dataService: any DataServiceProtocol
init(dataService: any DataServiceProtocol = DataService.shared) {
    self.dataService = dataService
}
```

### MockDataService Skeleton
```swift
// Source: [ASSUMED] - Standard mock pattern for Swift protocols

import Foundation
import Combine

@MainActor
class MockDataService: ObservableObject, DataServiceProtocol {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = Category.defaultCategories
    @Published var userProfile: UserProfile?

    var totalBalance: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }

    var totalExpensesThisMonth: Double {
        transactions.filter { $0.date.isThisMonth && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    var totalIncomeThisMonth: Double {
        transactions.filter { $0.date.isThisMonth && $0.isIncome }
            .reduce(0) { $0 + $1.amount }
    }

    func loadData() {
        // No-op for mock, or load preset test data
    }

    func category(for id: UUID) -> Category? {
        categories.first { $0.id == id }
    }

    func groupedTransactions() -> [(String, [Transaction])] {
        let sorted = transactions.sorted { $0.date > $1.date }
        let grouped = Dictionary(grouping: sorted) { $0.dateGroupTitle }
        let groupOrder = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { pair1, pair2 in
            if let idx1 = groupOrder.firstIndex(of: pair1.key),
               let idx2 = groupOrder.firstIndex(of: pair2.key) {
                return idx1 < idx2
            }
            return pair1.key > pair2.key
        }
    }

    func addTransaction(_ transaction: Transaction) {
        transactions.insert(transaction, at: 0)
    }

    func updateTransaction(_ transaction: Transaction) {
        if let index = transactions.firstIndex(where: { $0.id == transaction.id }) {
            var updated = transaction
            updated.updatedAt = Date()
            transactions[index] = updated
        }
    }

    func deleteTransaction(_ transaction: Transaction) {
        transactions.removeAll { $0.id == transaction.id }
    }
}
```

### MockAuthService Skeleton
```swift
// Source: [ASSUMED] - Standard mock pattern shaped by D-03/D-04 decisions

import Foundation
import Combine

@MainActor
class MockAuthService: ObservableObject, AuthServiceProtocol {
    @Published var authState: AuthState = .unauthenticated

    private var authStateListener: ((AuthState) -> Void)?
    var shouldFail: Bool = false
    var delay: TimeInterval = 0

    func register(email: String, password: String, name: String, gender: String, phone: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.shouldFail {
                completion(.failure(NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Registration failed"])))
            } else {
                let profile = UserProfile(preferences: UserPreferences())
                self.authState = .authenticated(profile)
                self.authStateListener?(self.authState)
                completion(.success(profile))
            }
        }
    }

    func login(email: String, password: String, completion: @escaping (Result<UserProfile, Error>) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            if self.shouldFail {
                completion(.failure(NSError(domain: "MockAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])))
            } else {
                let profile = UserProfile(preferences: UserPreferences())
                self.authState = .authenticated(profile)
                self.authStateListener?(self.authState)
                completion(.success(profile))
            }
        }
    }

    func logout(completion: @escaping (Result<Void, Error>) -> Void) {
        authState = .unauthenticated
        authStateListener?(authState)
        completion(.success(()))
    }

    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void) {
        authStateListener = listener
        listener(authState)
    }

    func removeAuthStateListener() {
        authStateListener = nil
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Implicit existential `Protocol` type | Explicit `any Protocol` | Swift 5.7 (2023) | Must write `any DataServiceProtocol`, not bare `DataServiceProtocol` |
| `some` for all protocol-typed properties | `any` when polymorphism needed | Swift 5.7+ | `any` required for DI where type varies at runtime |
| No actor isolation on protocols | `@MainActor` on protocol declarations | Swift 5.5+ | Prevents concurrency errors when ViewModels are @MainActor |
| Class-only protocols via `class` keyword | ` AnyObject` or inferred from requirements | Swift 4+ | ObservableObject inheritance already makes this class-only |

**Deprecated/outdated:**
- Bare protocol name as type (without `any` or `some`): Produces warning in Swift 5.7+, error in Swift 6 strict mode. Always use `any Protocol` for existentials.

## DataServiceProtocol Design

### Complete API Mapping from DataService.swift

Every public member of DataService mapped to protocol requirement:

| DataService Member | Kind | Protocol Requirement |
|--------------------|------|---------------------|
| `@Published var categories: [Category]` | Property | `var categories: [Category] { get }` |
| `@Published var transactions: [Transaction]` | Property | `var transactions: [Transaction] { get }` |
| `@Published var userProfile: UserProfile?` | Property | `var userProfile: UserProfile? { get }` |
| `var totalBalance: Double` | Computed | `var totalBalance: Double { get }` |
| `var totalExpensesThisMonth: Double` | Computed | `var totalExpensesThisMonth: Double { get }` |
| `var totalIncomeThisMonth: Double` | Computed | `var totalIncomeThisMonth: Double { get }` |
| `func loadData()` | Method | `func loadData()` |
| `func category(for id: UUID) -> Category?` | Method | `func category(for id: UUID) -> Category?` |
| `func groupedTransactions() -> [(String, [Transaction])]` | Method | `func groupedTransactions() -> [(String, [Transaction])]` |
| `func addTransaction(_ transaction: Transaction)` | Method | `func addTransaction(_ transaction: Transaction)` |
| `func updateTransaction(_ transaction: Transaction)` | Method | `func updateTransaction(_ transaction: Transaction)` |
| `func deleteTransaction(_ transaction: Transaction)` | Method | `func deleteTransaction(_ transaction: Transaction)` |

[VERIFIED: All members confirmed by reading DataService.swift]

### NOT in Protocol (by design, per D-12)
- `NotificationCenter.default.post(name: .transactionAdded/Updated/Deleted, ...)` -- implementation detail
- `static let shared = DataService()` -- singleton is a concrete concern
- `private init()` -- construction is a concrete concern
- `private func loadCategories()` / `loadTransactions()` / `loadUserProfile()` -- internal helpers

## ViewModel Refactoring

### Files to Change

| File | Current Type | New Type | Notes |
|------|-------------|----------|-------|
| `DashboardViewModel.swift` | `private let dataService: DataService` | `private let dataService: any DataServiceProtocol` | Init, property, all usages via protocol |
| `TransactionViewModel.swift` | `private let dataService: DataService` | `private let dataService: any DataServiceProtocol` | Init, property, all usages via protocol |
| `SettingsViewModel.swift` | `private let dataService: DataService` | `private let dataService: any DataServiceProtocol` | Init, property -- but barely uses dataService |

[VERIFIED: All 3 ViewModel files read and confirmed]

### No View Changes Required

Critical finding: No views use `@EnvironmentObject` to read DataService. All views create ViewModels via `@StateObject` with default init parameters. The `DataService.shared` default parameter means views need zero changes.

Verified: `grep -r "@EnvironmentObject" Views/` returned no results. [VERIFIED: codebase grep]

### Preview Block Impact

Two `#Preview` blocks reference `DataService.shared` directly:
- `CategoryPickerGrid.swift:69` -- `let dataService = DataService.shared`
- `TransactionRow.swift:52` -- `let dataService = DataService.shared`

These still work because `DataService.shared` still exists. No changes required. Optionally update for consistency.

## Mock Implementation Strategy

### MockDataService
- Place in `ExpenseTrackerAppTests/Mocks/MockDataService.swift`
- Must add to `ExpenseTrackerAppTests` build target in Xcode project
- Copy computed property implementations from DataService (totalBalance, grouping, etc.)
- No notification posting (MockDataService doesn't need it; tests call ViewModel.refreshData() directly)
- Support configurable initial state (empty by default, test can populate as needed)

### MockAuthService
- Place in `ExpenseTrackerAppTests/Mocks/MockAuthService.swift`
- Must add to `ExpenseTrackerAppTests` build target in Xcode project
- Configurable behavior: `shouldFail: Bool`, `delay: TimeInterval`
- Auth state starts as `.unauthenticated` by default (tests can set `.loading` to test loading states)

### Xcode Project Consideration
New files added to the filesystem are NOT automatically included in the Xcode build. The plan must include a step to add new `.swift` files to the appropriate target in `project.pbxproj`. In practice, this is done through Xcode's File > Add Files menu, or by editing the pbxproj directly. [ASSUMED]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Protocol inheriting `ObservableObject` is sufficient for `@StateObject`/`.environmentObject()` compatibility | Architecture Patterns | High -- if wrong, app entry point breaks. Mitigated: DataService already is ObservableObject, conformance is additive. |
| A2 | `@MainActor` on protocols is the correct pattern for ViewModels that are `@MainActor` | Architecture Patterns | Medium -- if wrong, compiler warnings about actor isolation. Swift 6 enforces this strictly, so compiler will catch it. |
| A3 | `any DataServiceProtocol` (not `some`) is correct for stored properties that need runtime polymorphism | Architecture Patterns | Low -- well-established Swift pattern since 5.7. |
| A4 | New files must be explicitly added to Xcode project target membership | Mock Implementation Strategy | High -- if wrong, tests can't find mock types. Must verify in implementation. |
| A5 | AuthState should be defined alongside AuthServiceProtocol (in the same file or a separate file) | Code Examples | Low -- organizational preference, no functional impact. |
| A6 | MockAuthService uses `DispatchQueue.main.asyncAfter` for simulating async behavior | Code Examples | Low -- alternative is async/await, but D-03 chose completion handlers. |

## Open Questions

1. **Protocol file organization**
   - What we know: CONTEXT.md gives Claude discretion on file organization.
   - What's unclear: Whether to use a `Protocols/` directory at the project root level or nest under `Services/`.
   - Recommendation: Use `Protocols/` as a new top-level directory. This keeps abstractions separate from implementations and matches the architecture research diagram. The codebase research (ARCHITECTURE.md) already shows this pattern.

2. **AuthState enum location**
   - What we know: D-04 defines AuthState with three cases. Needs to be defined somewhere.
   - What's unclear: Same file as AuthServiceProtocol, or separate file.
   - Recommendation: Same file as AuthServiceProtocol. It's a small enum tightly coupled to the auth protocol.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build, test | Yes | 16.4 (16F6) | -- |
| Swift compiler | All code | Yes | 6.1.2 | -- |
| iOS Simulator (iPhone 16) | Test execution | Yes | Available | -- |
| XCTest framework | Test target | Yes | Built-in | -- |

**Missing dependencies with no fallback:** None.

**Missing dependencies with fallback:** None.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | XCTest (Apple built-in) |
| Config file | None -- test targets configured in project.pbxproj |
| Quick run command | `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests` |
| Full suite command | `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ARCH-01 | DataServiceProtocol declares all DataService public API | Compile check | `xcodebuild build -scheme ExpenseTrackerApp ...` | N/A -- compile-time verification |
| ARCH-02 | AuthServiceProtocol declares auth methods | Compile check | `xcodebuild build -scheme ExpenseTrackerApp ...` | N/A -- compile-time verification |
| ARCH-03 | ViewModels accept protocol via init | Compile check + unit test | `xcodebuild test ... -only-testing:ExpenseTrackerAppTests` | No -- Wave 0 |
| ARCH-04 | MockDataService/MockAuthService conform to protocols | Compile check + unit test | `xcodebuild test ... -only-testing:ExpenseTrackerAppTests` | No -- Wave 0 |

**Important note:** The primary verification for this phase is that the app builds and runs identically to before. Protocol conformance is verified at compile time. Unit tests for mocks (confirming they work correctly) are Phase 5's scope (TEST-05, TEST-06). However, a basic smoke test confirming MockDataService can be created and used in a ViewModel init is valuable here.

### Sampling Rate
- **Per task commit:** `xcodebuild build -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'`
- **Per wave merge:** `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests`
- **Phase gate:** Full build + test run green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `ExpenseTrackerAppTests/Mocks/MockDataService.swift` -- mock implementation
- [ ] `ExpenseTrackerAppTests/Mocks/MockAuthService.swift` -- mock implementation
- [ ] Both files need to be added to `ExpenseTrackerAppTests` target in `project.pbxproj`
- [ ] Optional: `ExpenseTrackerAppTests/ProtocolSmokeTests.swift` -- basic test that MockDataService works in a ViewModel

## Security Domain

> This phase is purely structural refactoring with no external inputs, no authentication, no data persistence, and no network communication. Security enforcement is not applicable to this phase's scope.

**Security enforcement: Not applicable** -- protocol extraction is an internal architecture change. No new attack surface is introduced.

## Sources

### Primary (HIGH confidence)
- Codebase analysis: Read all 3 ViewModels, DataService, app entry point, models, constants -- every file that this phase touches
- `.planning/codebase/CONCERNS.md` -- Sections 1.3, 3.1, 3.2 document the tight coupling issues this phase resolves
- `.planning/codebase/TESTING.md` -- Test infrastructure, mock patterns, recommended organization
- `.planning/research/ARCHITECTURE.md` -- Recommended protocol-first architecture with component diagram
- `01-CONTEXT.md` -- User's locked decisions constraining the protocol design

### Secondary (MEDIUM confidence)
- Swift 6 `any`/`some` existential type pattern -- well-established Swift language feature [ASSUMED from training data, not verified via web search due to search unavailability]
- `@MainActor` protocol annotation pattern -- standard Swift concurrency practice [ASSUMED from training data]

### Tertiary (LOW confidence)
- None -- all findings are either codebase-verified or clearly marked as ASSUMED.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - No new dependencies, verified existing toolchain
- Architecture: HIGH - Protocol design directly mapped from existing DataService public API, all files read and verified
- Pitfalls: HIGH - Pitfalls identified from actual codebase analysis (e.g., Preview blocks, target membership)
- Mock patterns: MEDIUM - Implementation is straightforward but Xcode project file manipulation has edge cases

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (stable -- Swift language patterns, no fast-moving dependencies)

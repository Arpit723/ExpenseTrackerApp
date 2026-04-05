# Phase 1: Protocol Extraction - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Extract protocol abstractions from the existing concrete DataService and define AuthServiceProtocol so that all ViewModels depend on protocols rather than concrete types. Create mock implementations conforming to these protocols for testing. The app must build and run identically after extraction — no behavior changes, only structural refactoring.

This phase does NOT add Firebase, auth views, or any new user-facing features.
</domain>

<decisions>
## Implementation Decisions

### Protocol Design
- **D-01:** One protocol per service — `DataServiceProtocol` and `AuthServiceProtocol` (no interface segregation)
- **D-02:** DataServiceProtocol mirrors all public API of the current DataService: CRUD operations, computed properties (totalBalance, totalIncomeThisMonth, totalExpensesThisMonth), helper methods (category(for:), groupedTransactions()), and Published-wrapping accessors
- **D-03:** AuthServiceProtocol declares: register(email:password:name:gender:phone:completion:), login(email:password:completion:), logout(completion:), addAuthStateListener(_:), removeAuthStateListener()
- **D-04:** AuthState enum with three cases: loading, authenticated, unauthenticated — published by any AuthServiceProtocol conformance

### Dependency Injection
- **D-05:** All ViewModels change their `dataService` property type from `DataService` to `any DataServiceProtocol`
- **D-06:** ViewModels init signature changes from `init(dataService: DataService = .shared)` to `init(dataService: any DataServiceProtocol = DataService.shared)`
- **D-07:** Existing DataService conforms to DataServiceProtocol
- **D-08:** App entry point continues to use DataService.shared — no changes to production wiring yet

### Mock Implementations
- **D-09:** MockDataService conforming to DataServiceProtocol — stores data in-memory arrays (like current DataService), supports all CRUD and computed properties
- **D-10:** MockAuthService conforming to AuthServiceProtocol — simulates auth state with configurable behavior (auto-succeed, auto-fail, delay)
- **D-11:** Mocks placed in test target (not main app target) since they're only needed for testing

### Notification Handling
- **D-12:** Notification posting stays in DataService (concrete implementation detail). DataServiceProtocol does NOT declare notification posting — it's an implementation concern, not a contract
- **D-13:** ViewModels continue listening to notifications in setupBindings() — this is fine for now, can be replaced with direct observation in Phase 5 if needed

### Reactivity Bridging
- **D-14:** DataServiceProtocol declares properties as `var transactions: [Transaction] { get }` (not @Published). The concrete DataService uses @Published internally but the protocol only requires getter access
- **D-15:** ViewModels that need reactive updates from data changes continue using NotificationCenter observers — this works with any DataServiceProtocol conformance since the concrete types post notifications

### Claude's Discretion
- Exact file organization for protocols (single file per protocol, or grouped)
- Whether to use `any Protocol` or `some Protocol` in ViewModel property declarations
- Mock implementation details (how configurable, which edge cases to support)
- Whether to add documentation comments to protocol declarations
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Current service implementation
- `ExpenseTrackerApp/Services/DataService.swift` — The concrete service being extracted into protocol
- `ExpenseTrackerApp/ExpenseTrackerAppApp.swift` — App entry point, creates DataService.shared

### ViewModels to refactor
- `ExpenseTrackerApp/ViewModels/DashboardViewModel.swift` — Uses `private let dataService: DataService`
- `ExpenseTrackerApp/ViewModels/TransactionViewModel.swift` — Uses `private let dataService: DataService`
- `ExpenseTrackerApp/ViewModels/SettingsViewModel.swift` — Uses `private let dataService: DataService`

### Models referenced by DataService
- `ExpenseTrackerApp/Models/Transaction.swift` — Transaction struct used in CRUD
- `ExpenseTrackerApp/Models/Category.swift` — Category struct, defaultCategories
- `ExpenseTrackerApp/Models/UserProfile.swift` — UserProfile struct

### Constants and utilities
- `ExpenseTrackerApp/Utils/Constants.swift` — Notification.Name extensions used by DataService

### Codebase analysis
- `.planning/codebase/ARCHITECTURE.md` — Current MVVM architecture, data flow diagrams
- `.planning/codebase/CONCERNS.md` — Documented tight coupling issues (sections 1.3, 3.1, 3.2)

### Research
- `.planning/research/ARCHITECTURE.md` — Recommended protocol extraction approach
- `.planning/research/SUMMARY.md` — Key findings on protocol-first approach
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `DataService` already has clean public API — protocol extraction is straightforward, just copy the signatures
- All 3 ViewModels already accept DataService via init with default `.shared` — the DI pattern is already established, just needs type generalization
- Models already conform to `Codable`, `Identifiable`, `Hashable` — no model changes needed for protocol extraction

### Established Patterns
- ViewModel init pattern: `init(dataService: DataService = .shared)` — will become `init(dataService: any DataServiceProtocol = DataService.shared)`
- Notification-based updates: DataService posts `.transactionAdded/Updated/Deleted`, ViewModels subscribe in `setupBindings()` — stays as-is
- `@MainActor` on all ViewModels — protocols should also be `@MainActor` annotated

### Integration Points
- `ExpenseTrackerAppApp.swift` creates `@StateObject` DataService and injects via `.environmentObject()` — after extraction, still creates concrete DataService (which now conforms to protocol)
- Views create `@StateObject` ViewModels with default init — these still work because default parameter is `DataService.shared`
- `CategoryPickerGrid.swift` #Preview block references `DataService.shared` directly — may need updating
</code_context>

<specifics>
## Specific Ideas

- Registration will collect Name, Gender, Phone Number alongside Email/Password (from user questioning) — AuthServiceProtocol should declare register with these parameters
- Unit tests should be written with mock services, not against Firebase — protocol extraction enables this
- 80% code coverage target on ViewModels and Services (from REQUIREMENTS.md)
</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope
</deferred>

---

*Phase: 01-protocol-extraction*
*Context gathered: 2026-04-05*

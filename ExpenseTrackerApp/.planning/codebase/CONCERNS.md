# CONCERNS.md — Technical Debt, Bugs, Security & Fragile Areas

**Generated:** 2026-04-05
**Codebase:** ExpenseTrackerApp (Swift/SwiftUI iOS)

---

## 1. Critical Concerns

### 1.1 No Data Persistence
- **Location:** `ExpenseTrackerApp/Services/DataService.swift`
- **Issue:** All data is in-memory. App resets on every launch.
- **Impact:** Users lose all transactions on app close.
- **SRS Reference:** NFR-3.2 requires data persistence across launches.
- **Planned Fix:** Firebase Firestore integration (SRS v3.0).

### 1.2 No Authentication
- **Location:** `ExpenseTrackerApp/ExpenseTrackerAppApp.swift`
- **Issue:** No login/register flow. Anyone can access the app.
- **Impact:** No user identity, no data isolation, no security.
- **SRS Reference:** FR-5 requires Firebase Auth integration.
- **Planned Fix:** Firebase Auth with Email/Password (SRS v3.0).

### 1.3 No Service Protocol Abstraction
- **Location:** `ExpenseTrackerApp/Services/DataService.swift`
- **Issue:** `DataService` is a concrete class (singleton), not a protocol.
- **Impact:** ViewModels are tightly coupled to `DataService.shared`. Cannot mock for unit testing.
- **SRS Reference:** NFR-5.4 requires protocol-based services for DI and mocking.
- **Planned Fix:** Extract `DataServiceProtocol`, create mock and Firebase implementations.

---

## 2. High-Priority Concerns

### 2.1 NumberFormatter Created on Every Call
- **Location:** `Transaction.swift:54-58`, `Double+Currency.swift:11-15`
- **Issue:** `formattedAmount` and `formattedAsCurrency()` create a new `NumberFormatter` per call.
- **Impact:** Performance degradation with large transaction lists (1000+ items scrolling).
- **NFR Reference:** NFR-1.2 requires 60fps with 1000 transactions.
- **Fix:** Use static `NumberFormatter` instances or `FormatStyle` (iOS 15+).

### 2.2 DateFormatter Created on Every Call
- **Location:** `Date+Extensions.swift:63-66`
- **Issue:** `formatted(with:)` creates a new `DateFormatter` per call.
- **Impact:** Same performance issue as NumberFormatter above.
- **Fix:** Use static formatter cache or iOS 15+ `FormatStyle`.

### 2.3 Currency Not Respected in Formatting
- **Location:** `Transaction.swift:55` — hardcoded `"USD"`, `Double+Currency.swift:11` — defaults to `"USD"`
- **Issue:** User can change currency in Settings but transaction display still shows `$` and USD.
- **Impact:** Incorrect currency display for non-USD users.
- **Fix:** Pass user's selected currency code through to formatting functions.

### 2.4 No Error Handling in Formatters
- **Location:** `Transaction.swift:54-60`, `Double+Currency.swift:11-16`
- **Issue:** Fallback values (`"$0.00"`) silently hide formatting errors.
- **Impact:** Debugging difficulty if currency formatting breaks.

---

## 3. Medium-Priority Concerns

### 3.1 Singleton Pattern in DataService
- **Location:** `DataService.swift:13` — `static let shared = DataService()`
- **Issue:** Singleton makes testing difficult and creates hidden global state.
- **Impact:** Cannot inject test data, cannot run parallel tests.
- **Fix:** Use dependency injection via `@EnvironmentObject` or protocol-based injection.

### 3.2 ViewModels Directly Instantiate Dependencies
- **Locations:**
  - `DashboardViewModel.swift:32` — `private let dataService: DataService`
  - `TransactionViewModel.swift:51` — `private let dataService: DataService`
  - `SettingsViewModel.swift:20` — `private let dataService: DataService`
- **Issue:** Default parameter `DataService.shared` couples ViewModels to singleton.
- **Impact:** Cannot swap implementations for testing.
- **Fix:** Inject via `@EnvironmentObject` or init parameter with protocol.

### 3.3 Notification-Based Updates Are Fragile
- **Location:** `DashboardViewModel.swift:34-47`, `DataService.swift:206-222`
- **Issue:** Using `NotificationCenter` for inter-component communication. Notifications are stringly-typed and easy to misspell or forget to observe.
- **Impact:** Race conditions possible if notification fires before observer is set up.
- **Fix:** Consider Combine pipelines or direct observation of `@Published` properties.

### 3.4 `@StateObject` in View Bodies
- **Location:** `DashboardView.swift:12`, `TransactionsView.swift:11`, `AddTransactionView.swift:12`, `SettingsView.swift:11`
- **Issue:** `@StateObject private var viewModel = SomeViewModel()` creates new ViewModel per view lifecycle. The ViewModel's `init()` calls `DataService.shared`, triggering data loads every time the view appears.
- **Impact:** Unnecessary data reloads, potential flicker.
- **Fix:** Inject ViewModels from parent or use `@EnvironmentObject`.

### 3.5 No Input Validation on Transaction Amount
- **Location:** `AddTransactionView.swift` — `saveTransaction()` method
- **Issue:** Only checks `amountValue > 0` but doesn't validate precision (e.g., user enters 10.001).
- **Impact:** Floating-point precision issues in balance calculations.
- **SRS Reference:** DR-1 — amount must be non-zero.
- **Fix:** Round to 2 decimal places before saving.

---

## 4. Low-Priority Concerns

### 4.1 Hardcoded Strings in Views
- **Locations:** Multiple view files (e.g., "Dashboard", "Transactions", "Settings")
- **Issue:** UI strings are hardcoded, not localized.
- **Impact:** Cannot support multiple languages.
- **Note:** SRS currently only targets English, so this is acceptable.

### 4.2 Sample Data in DataService
- **Location:** `DataService.swift:37-155` — `loadTransactions()` method
- **Issue:** 16 hardcoded sample transactions are loaded every time.
- **Impact:** After Firebase integration, this sample data should only appear for new users or be removed.
- **Fix:** Gate sample data behind a "first launch" flag or remove after Firebase integration.

### 4.3 No Empty State for Dashboard
- **Location:** `DashboardView.swift`
- **Issue:** Dashboard shows balance card and monthly summary even with zero transactions, but recent transactions section has an empty state.
- **Impact:** NFR-3.3 requires informative placeholders.
- **Fix:** Add a more prominent first-launch experience or empty dashboard state.

### 4.4 QuickActionButton Still References QuickAmountButton
- **Location:** `QuickActionButton.swift`
- **Issue:** File contains both `QuickActionButton`, `QuickAmountButton`, and `FloatingAddButton`. The `QuickAmountButton` is only used in AddTransactionView's preview.
- **Impact:** Dead code in production.
- **Fix:** Consider removing unused `QuickAmountButton` struct.

---

## 5. Security Concerns

### 5.1 No Data Isolation
- **Issue:** All users would share the same in-memory data store.
- **Impact:** Critical after multi-user support (Firebase Auth).
- **Planned Fix:** Firestore collections scoped by `users/{uid}/`.

### 5.2 No Input Sanitization
- **Location:** `AddTransactionView.swift` — payee and notes fields
- **Issue:** Free-text fields have no length limits or sanitization.
- **Impact:** Potential for extremely long strings causing UI issues.
- **Fix:** Add character limits (e.g., 100 chars for payee, 500 for notes).

---

## 6. Test Coverage

### 6.1 Zero Test Coverage
- **Location:** `ExpenseTrackerAppTests/ExpenseTrackerAppTests.swift`
- **Issue:** Only boilerplate test file exists. No actual test cases.
- **Impact:** No automated verification of business logic.
- **SRS Reference:** Section 9 requires 80% coverage on ViewModels and Services.
- **Blocker:** Cannot write meaningful tests until services use protocols (see 1.3).

---

## Summary

| Priority | Count | Key Areas |
|----------|-------|-----------|
| Critical | 3 | No persistence, no auth, no protocol abstraction |
| High | 4 | Formatter performance, currency not respected |
| Medium | 5 | Singletons, notification fragility, input validation |
| Low | 4 | Localization, sample data, dead code |
| Security | 2 | Data isolation, input sanitization |
| Testing | 1 | Zero coverage |

**Top 3 blockers for SRS v3.0:**
1. Service protocol extraction (blocks testing + Firebase migration)
2. Firebase Auth integration (blocks auth flow)
3. Firebase Firestore integration (blocks persistence)

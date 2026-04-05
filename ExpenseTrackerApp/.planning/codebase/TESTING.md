# Testing Patterns

**Analysis Date:** 2026-04-05

## Test Framework

**Runner:**
- XCTest (Apple's built-in testing framework)
- No custom test configuration files (no `.xctestplan` detected)
- Test targets defined in `ExpenseTrackerApp.xcodeproj/project.pbxproj`

**Assertion Library:**
- XCTest built-in assertions (`XCTAssert`, `XCTAssertEqual`, `XCTAssertTrue`, etc.)
- No third-party assertion libraries

**Run Commands:**
```bash
# Run all tests
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run unit tests only
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests

# Run UI tests only
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppUITests

# In Xcode
# Cmd+U to run all tests
```

## Test File Organization

**Location:**
- Separate test target directories (not co-located with source)
- Unit tests: `ExpenseTrackerAppTests/`
- UI tests: `ExpenseTrackerAppUITests/`
- Both directories are siblings to the main `ExpenseTrackerApp/` source directory

**Naming:**
- Default Xcode naming: `ExpenseTrackerAppTests.swift`, `ExpenseTrackerAppUITests.swift`
- No feature-specific test files exist yet

**Structure:**
```
ExpenseTrackerApp/                         # Project root
├── ExpenseTrackerApp/                     # Source code
├── ExpenseTrackerAppTests/                # Unit test target
│   └── ExpenseTrackerAppTests.swift       # Empty template
├── ExpenseTrackerAppUITests/              # UI test target
│   ├── ExpenseTrackerAppUITests.swift      # Empty template
│   └── ExpenseTrackerAppUITestsLaunchTests.swift  # Launch screenshot test
└── ExpenseTrackerApp.xcodeproj/           # Project config
```

## Test Structure

**Suite Organization:**
- Xcode-generated template class with `setUpWithError` / `tearDownWithError` lifecycle
- Current state (from `ExpenseTrackerAppTests/ExpenseTrackerAppTests.swift`):
```swift
import XCTest
@testable import ExpenseTrackerApp

final class ExpenseTrackerAppTests: XCTestCase {
    override func setUpWithError() throws {
        // Setup before each test
    }

    override func tearDownWithError() throws {
        // Teardown after each test
    }

    func testExample() throws {
        // Placeholder — no real tests written
    }

    func testPerformanceExample() throws {
        self.measure {
            // Placeholder performance test
        }
    }
}
```

**UI Test Template (from `ExpenseTrackerAppUITests/ExpenseTrackerAppUITests.swift`):**
```swift
import XCTest

final class ExpenseTrackerAppUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testExample() throws {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
```

**Patterns:**
- `@MainActor` annotation on UI test methods
- `continueAfterFailure = false` in UI test setup
- `@testable import ExpenseTrackerApp` for internal access in unit tests

## Mocking

**Framework:** None (no mocking frameworks like Cuckoo, Mockolo, or Sourcery)

**Patterns:**
- No mocks, stubs, or fakes currently exist in the codebase
- The architecture supports mocking through protocol-based injection but does not use it yet
- `DataService` is a concrete singleton (`DataService.shared`) injected via default parameter:
  ```swift
  init(dataService: DataService = .shared)
  ```
  This allows test injection but no protocol abstraction exists

**What to Mock:**
- `DataService` — the central data store. Tests should inject a controlled instance rather than using `.shared` with sample data
- Notification publishers — ViewModels subscribe to `NotificationCenter.default.publisher`; tests should control when these fire

**What NOT to Mock:**
- Model structs (`Transaction`, `Category`, `UserProfile`) — these are simple value types, create instances directly
- Extension methods on `Date`, `Double`, `Color` — test these as-is

**Approach for Adding Mocks:**
- Extract a `DataServiceProtocol` from `DataService` and have ViewModels depend on the protocol
- Create a `MockDataService` conforming to the protocol for testing
- Alternative: reset `DataService.shared` state by calling `loadData()` with controlled inputs

## Fixtures and Factories

**Test Data:**
- No dedicated test fixtures or factories
- `DataService.loadTransactions()` creates sample data in-memory, but this is production sample data, not test fixtures
- For tests, create model instances directly using initializers:
```swift
let category = Category(name: "Test Food", icon: "fork.knife", color: "#FF6B6B")
let transaction = Transaction(
    amount: -25.50,
    categoryId: category.id,
    date: Date(),
    payee: "Test Coffee Shop",
    notes: "Test note"
)
```

**Location:**
- No fixture directory exists
- When adding fixtures, place them in `ExpenseTrackerAppTests/Helpers/` or `ExpenseTrackerAppTests/Fixtures/`

## Coverage

**Requirements:** None enforced (no minimum coverage threshold configured)

**View Coverage:**
```bash
# Generate coverage report
xcodebuild test -scheme ExpenseTrackerApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES
```

**Current Coverage:** Effectively 0% — no meaningful tests exist beyond empty templates.

## Test Types

**Unit Tests:**
- Target: `ExpenseTrackerAppTests`
- File: `ExpenseTrackerAppTests/ExpenseTrackerAppTests.swift`
- Status: Empty template only — no real unit tests
- Priority areas for unit testing:
  - `DataService` computed properties (`totalBalance`, `totalIncomeThisMonth`, `totalExpensesThisMonth`)
  - `DataService` CRUD operations (`addTransaction`, `updateTransaction`, `deleteTransaction`)
  - `DataService.groupedTransactions()` date grouping and sorting logic
  - `Transaction` computed properties (`isExpense`, `isIncome`, `displayAmount`, `dateGroupTitle`)
  - `TransactionViewModel` filtering and sorting logic (`applyFilters`)
  - `TransactionViewModel` search functionality
  - `DashboardViewModel.refreshData()` aggregation logic
  - `Date+Extensions` helper methods
  - `Double+Currency` formatting
  - `Color+Theme` hex conversion

**Integration Tests:**
- None exist
- ViewModel + DataService integration would be valuable:
  - Verify that adding a transaction via ViewModel updates DataService
  - Verify that notification-based refresh works correctly

**E2E Tests:**
- Target: `ExpenseTrackerAppUITests`
- Files: `ExpenseTrackerAppUITests.swift`, `ExpenseTrackerAppUITestsLaunchTests.swift`
- Status: Empty template with launch screenshot capture only
- Priority flows for E2E testing:
  - Add a transaction via FAB button, verify it appears on dashboard and transactions list
  - Edit a transaction, verify updated values display
  - Delete a transaction via swipe action, verify removal
  - Filter transactions by income/expense
  - Search transactions by payee name
  - Navigate between tabs

## Common Patterns

**Async Testing:**
- Use `async/await` test methods marked with `async throws`:
```swift
func testRefreshData() async throws {
    let viewModel = DashboardViewModel(dataService: testDataService)
    await viewModel.refresh()
    XCTAssertEqual(viewModel.totalBalance, expectedBalance)
}
```
- For Combine-based async code, use `XCTestExpectation`:
```swift
func testNotificationUpdates() {
    let expectation = XCTestExpectation(description: "Data refreshed after notification")
    // ... trigger notification, fulfill expectation in sink
    wait(for: [expectation], timeout: 2.0)
}
```

**Error Testing:**
- Not applicable currently (no throwing functions in codebase)
- Pattern for future use:
```swift
func testInvalidAmount() throws {
    let transaction = Transaction(amount: 0, categoryId: UUID())
    XCTAssertTrue(transaction.amount == 0)
    XCTAssertFalse(transaction.isExpense)
    XCTAssertFalse(transaction.isIncome)
}
```

**Testing DataService Directly:**
```swift
// Since DataService is a singleton, create fresh state for each test
func testAddTransaction() {
    let service = DataService.shared
    let initialCount = service.transactions.count
    let transaction = Transaction(amount: -50.0, categoryId: service.categories[0].id)
    service.addTransaction(transaction)
    XCTAssertEqual(service.transactions.count, initialCount + 1)
    XCTAssertEqual(service.transactions.first?.id, transaction.id)
}
```

**Testing ViewModel Filtering:**
```swift
func testFilterByExpense() {
    let viewModel = TransactionViewModel(dataService: DataService.shared)
    viewModel.selectedFilter = .expenses
    // Apply filters is private, trigger via loadTransactions
    viewModel.loadTransactions()
    XCTAssertTrue(viewModel.filteredTransactions.allSatisfy { $0.isExpense })
}
```

## Recommended Test Organization

When writing tests, follow this file structure:

```
ExpenseTrackerAppTests/
├── ExpenseTrackerAppTests.swift           # Keep existing file
├── Models/
│   ├── TransactionTests.swift             # Transaction computed properties
│   ├── CategoryTests.swift                # Category defaults, color conversion
│   └── UserProfileTests.swift             # User preferences
├── ViewModels/
│   ├── DashboardViewModelTests.swift      # Balance calculations, refresh
│   ├── TransactionViewModelTests.swift    # Filtering, sorting, search, CRUD
│   └── SettingsViewModelTests.swift       # Currency, theme persistence
├── Services/
│   └── DataServiceTests.swift             # CRUD, computed totals, grouping
└── Utils/
    ├── DateExtensionsTests.swift           # Date helpers
    └── DoubleCurrencyTests.swift           # Currency formatting
```

## Test Configuration Notes

**DataService Singleton Consideration:**
- `DataService.shared` is a singleton with `private init()`. For isolated unit tests, either:
  1. Use the shared instance and call `loadData()` to reset state between tests
  2. Refactor `DataService` to use a protocol so tests can inject a fresh mock
  3. Add a `static func resetForTesting()` method that reinitializes the singleton

**Notification Cleanup:**
- ViewModels subscribe to `NotificationCenter` in `setupBindings()`. Tests must ensure subscriptions are properly torn down to avoid cross-test interference
- Consider adding a `cancel()` method to ViewModels that clears `cancellables`

**@MainActor ViewModels:**
- All ViewModels are `@MainActor`, so test methods accessing them must also run on the main actor
- Use `@MainActor` annotation on test methods or wrap calls in `MainActor.assumeIsolated`

---

*Testing analysis: 2026-04-05*

---
name: xctest-generator
description: Generate XCTest unit tests for SwiftUI MVVM apps with protocol-based dependency injection. Use when adding tests for ViewModels, Services, or Models — creates protocol mocks, test cases, and helps reach coverage targets.
---

# XCTest Generator Skill

## Operating Rules

- Generate tests using `XCTest` framework — no third-party testing libraries
- Create mock implementations for all protocol-based dependencies
- Use `@MainActor` on test classes testing `@MainActor` ViewModels
- Test behavior, not implementation details — verify outputs given inputs
- Name tests descriptively: `test_<method>_<scenario>_<expectedResult>`
- Aim for 80%+ code coverage on ViewModels and Services
- Place mocks in the test target, not the app target
- Use `setUp()` and `tearDown()` for test isolation

## Task Workflow

### Generate tests for a ViewModel

1. **Read the ViewModel** to understand:
   - Published properties (these are the outputs to verify)
   - Methods (these are the inputs to test)
   - Dependencies (these need mocking)
2. **Create/update mock** for each protocol dependency:
   ```swift
   class MockDataService: DataServiceProtocol {
       var transactions: [Transaction] = []
       var addTransactionCalled = false
       var addTransactionCallCount = 0

       func addTransaction(_ transaction: Transaction) {
           addTransactionCalled = true
           addTransactionCallCount += 1
           transactions.append(transaction)
       }
   }
   ```
3. **Generate test file** with test cases covering:
   - Happy path (valid inputs → expected outputs)
   - Edge cases (empty data, zero values, nil optionals)
   - Error states (invalid inputs, service failures)
   - State transitions (filter changes, sort changes)
4. **Run tests** to verify they compile and pass:
   ```bash
   xcodebuild test -scheme ExpenseTrackerApp \
     -destination 'platform=iOS Simulator,name=iPhone 16' \
     -only-testing:ExpenseTrackerAppTests
   ```

### Generate tests for a Service

1. **Read the Service** to identify:
   - Public methods and their contracts
   - Computed properties and their dependencies
   - Side effects (notifications, state mutations)
2. **Test each public method** independently
3. **Verify side effects**: check `NotificationCenter` postings, state changes
4. **Test computed properties** with varied data sets

### Generate tests for a Model

1. **Read the Model** to identify:
   - Computed properties (formatters, derived values)
   - Initializers and factory methods
   - Codable conformance (encode/decode round-trip)
   - Equality and hashing
2. **Test computed properties** with known inputs/outputs
3. **Test Codable** round-trip: encode → decode → compare
4. **Test edge cases**: negative amounts, empty strings, future/past dates

## Test Naming Convention

```
test_<methodName>_<scenario>_<expectedResult>

// Examples:
test_addTransaction_validTransaction_increasesCount()
test_formattedAmount_positiveAmount_showsDollarSign()
test_totalBalance_noTransactions_returnsZero()
test_filterTransactions_incomeFilter_returnsOnlyIncome()
test_deleteTransaction_existingTransaction_removesFromList()
```

## Test Structure Template

```swift
import XCTest
@testable import ExpenseTrackerApp

@MainActor
final class DashboardViewModelTests: XCTestCase {

    var sut: DashboardViewModel!  // System Under Test
    var mockDataService: MockDataService!

    override func setUp() {
        super.setUp()
        mockDataService = MockDataService()
        sut = DashboardViewModel(dataService: mockDataService)
    }

    override func tearDown() {
        sut = nil
        mockDataService = nil
        super.tearDown()
    }

    // MARK: - Balance Tests

    func test_totalBalance_noTransactions_returnsZero() {
        // Given
        mockDataService.transactions = []

        // When
        sut.refreshData()

        // Then
        XCTAssertEqual(sut.totalBalance, 0.0)
    }

    func test_totalBalance_mixedTransactions_returnsCorrectSum() {
        // Given
        mockDataService.transactions = [
            Transaction(amount: 1000, categoryId: incomeCategory.id, payee: "Salary"),
            Transaction(amount: -50, categoryId: foodCategory.id, payee: "Lunch"),
        ]

        // When
        sut.refreshData()

        // Then
        XCTAssertEqual(sut.totalBalance, 950.0)
    }
}
```

## Mock Template

```swift
@testable import ExpenseTrackerApp

class MockDataService: DataServiceProtocol {
    // State
    var transactions: [Transaction] = []
    var categories: [Category] = Category.defaultCategories

    // Call tracking
    var addTransactionCallCount = 0
    var deleteTransactionCallCount = 0

    // Methods
    func addTransaction(_ transaction: Transaction) {
        addTransactionCallCount += 1
        transactions.append(transaction)
    }

    func deleteTransaction(_ id: UUID) {
        deleteTransactionCallCount += 1
        transactions.removeAll { $0.id == id }
    }

    // Computed — mirror real service or customize for tests
    var totalBalance: Double {
        transactions.reduce(0) { $0 + $1.amount }
    }
}
```

## Coverage Checklist

For each ViewModel/Service, verify tests cover:

- [ ] All public methods called at least once
- [ ] All published/computed properties verified with known values
- [ ] Empty state (no data)
- [ ] Single item state
- [ ] Multiple items state
- [ ] Filter/sort transformations (if applicable)
- [ ] Error/invalid input handling
- [ ] Notification observation (if applicable)
- [ ] Codable round-trip (for models)

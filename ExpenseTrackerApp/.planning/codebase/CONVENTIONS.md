# Coding Conventions

**Analysis Date:** 2026-04-05

## Naming Patterns

**Files:**
- PascalCase matching the primary type/struct/enum they define: `DashboardView.swift`, `TransactionRow.swift`, `Color+Theme.swift`
- Extensions on existing types use `Type+Extension` naming: `Color+Theme.swift`, `Date+Extensions.swift`, `Double+Currency.swift`
- One primary type per file (exceptions: small helper types like `FilterChip` embedded in the same file as the view that uses it)

**Structs/Classes:**
- PascalCase: `Transaction`, `DashboardViewModel`, `CategoryPickerGrid`
- Models are structs; ViewModels and services are classes

**Enums:**
- PascalCase for type names: `TransactionFilter`, `TransactionSort`, `AppTheme`
- camelCase for cases: `.all`, `.income`, `.expenses`, `.dateDescending`

**Functions:**
- camelCase: `refreshData()`, `addTransaction(_:)`, `formattedAsCurrency()`
- Private helpers are extracted: `private var balanceCard: some View`, `private func saveTransaction()`

**Variables:**
- camelCase: `totalBalance`, `selectedFilter`, `showingAddTransaction`
- Boolean state variables prefixed with `is` or `showing`: `isExpense`, `isLoading`, `showingCategoryPicker`, `showingDeleteConfirmation`

**Constants:**
- Static let on `Constants` struct: `Constants.Layout.cornerRadius`, `Constants.Animation.default`
- Nested structs for grouping: `Constants.Layout`, `Constants.Animation`, `Constants.Colors`

**Types:**
- All models conform to `Identifiable`, `Codable`, `Hashable`
- UUID-based `id` property on all models
- Enums use `String` raw values and conform to `CaseIterable`, `Codable`

## Code Style

**Formatting:**
- No external formatter detected (Swift default indentation)
- Xcode-generated file headers: `//\n//  FileName.swift\n//  ExpenseTrackerApp\n//\n//  Created by Arpit Parekh on 28/03/26.\n//`
- Consistent 4-space indentation

**Linting:**
- No linter configured (no SwiftLint, no custom build phase linting)

**MARK Comments:**
- Heavy use of `// MARK: - Section Name` throughout all files
- Used in every file to separate logical sections
- View bodies use `// MARK: - Section Name` to delineate extracted view properties
- Pattern: `// MARK: - Published Properties`, `// MARK: - Dependencies`, `// MARK: - Initialization`, `// MARK: - Computed Properties`, `// MARK: - Helper Methods`, `// MARK: - CRUD Operations`

## Import Organization

**Order:**
1. Foundation framework first (when needed)
2. SwiftUI second
3. Combine third (when needed)
4. No other imports (zero external dependencies)

**Pattern observed in all files:**
```swift
import Foundation
import SwiftUI
import Combine  // only in files that use Combine
```

**No path aliases** -- standard module imports only.

## Error Handling

**Patterns:**
- No formal error handling (`throws`, `Result`, `Error` types) anywhere in the codebase
- Optional chaining for nullable values: `transaction.payee?.localizedCaseInsensitiveContains(searchText)`
- Nil coalescing for fallbacks: `Color(hex: color) ?? .gray`, `formatter.string(from:) ?? "$0.00"`
- Guard-let for early returns in action methods: `guard let amountValue = Double(amount), let category = selectedCategory, amountValue > 0 else { return }`
- `try?` used for optional async work: `try? await Task.sleep(nanoseconds: 300_000_000)`

**Validation:**
- Form validation via computed `isValidForm` property checking `amountValue > 0 && selectedCategory != nil`
- Save button disabled when form is invalid: `.disabled(!isValidForm)`

## Logging

**Framework:** None (no `os.log`, `os.signpost`, or third-party logging)

**Patterns:**
- No logging statements anywhere in the codebase
- Debugging relies on Xcode previews and SwiftUI preview macros
- `#Preview` blocks at the bottom of every view file

## Comments

**When to Comment:**
- `// MARK: -` comments are used extensively for navigation
- SRS requirement references inline: `// MARK: - Income/Expense Toggle (FR-2.1)`, `// MARK: - Recent Transactions (last 10 -- FR-1.3)`
- Section comments explain business rules: `// Search across payee and notes (FR-2.5)`, `// Filter by type (FR-2.6)`
- Otherwise minimal comments -- code is self-documenting

**JSDoc/TSDoc:**
- Not used. No doc comments on any function, property, or type.

## Function Design

**Size:**
- View body properties are decomposed into extracted sub-views (computed properties returning `some View`)
- Example from `ExpenseTrackerApp/Views/Dashboard/DashboardView.swift`:
  ```swift
  private var balanceCard: some View { ... }
  private var monthlySummarySection: some View { ... }
  private var recentTransactionsSection: some View { ... }
  private var emptyTransactionsPlaceholder: some View { ... }
  private var transactionsList: some View { ... }
  ```
- Action functions are short and focused: `saveTransaction()`, `deleteTransaction(_:)`

**Parameters:** Use argument labels for clarity: `formattedAsCurrency(currencyCode:)`, `adding(days:)`

**Return Values:**
- ViewModels return concrete types, not optionals, for UI state
- Helper lookups return optionals: `func category(for id: UUID) -> Category?`
- Computed properties for derived data: `var isExpense: Bool`, `var displayAmount: String`

## Module Design

**Exports:**
- Each file exports one primary type
- Small helper types (like `FilterChip`, `CategoryIconView`, `FloatingAddButton`, `QuickAmountButton`, `TabBarButton`, `CategoryPickerSheet`) are defined in the same file as the primary view that uses them
- No barrel files or module index files

**Barrel Files:**
- Not used. All imports reference specific types via the module `ExpenseTrackerApp`

## Architecture Patterns

**MVVM:**
- Views: SwiftUI `View` structs in `Views/` directory
- ViewModels: `@MainActor ObservableObject` classes in `ViewModels/` directory
- Models: Value-type structs in `Models/` directory

**View-ViewModel Binding:**
- Views create ViewModels via `@StateObject private var viewModel = SomeViewModel()`
- ViewModels receive `DataService` via dependency injection with default parameter: `init(dataService: DataService = .shared)`
- `@Published` properties on ViewModels drive view updates
- `DataService` injected at app root via `.environmentObject(dataService)` in `ExpenseTrackerApp/ExpenseTrackerAppApp.swift`

**Notification-Based Updates:**
- `DataService` posts `Notification.Name` notifications after CRUD operations
- ViewModels subscribe via Combine publishers in `setupBindings()`
- Views also subscribe directly via `.onReceive()` modifier
- Notification names defined as `Notification.Name` extensions in `ExpenseTrackerApp/Utils/Constants.swift`

**Color System:**
- Always use theme colors from `Color+Theme.swift`: `Color.appPrimary`, `Color.appSuccess`, `Color.appDanger`, etc.
- Never hardcode hex values in views -- use `Color(hex:)` initializer or theme constants
- Category colors stored as hex strings, converted via `Color(hex:)` in `Category.swift`

**Layout Constants:**
- Use `Constants.Layout.*` for spacing, padding, corner radius
- Use `Constants.Animation.*` for animation durations
- Avoid magic numbers in views

**Date Formatting:**
- Use `Date+Extensions` helpers: `.relativeString`, `.shortDate`, `.timeOnly`, `.monthYear`
- Custom formatting: `.formatted(with: "MMM d, yyyy")`
- Note: `DateFormatter` is created per-call in extensions (not cached in static property) -- a potential performance concern

**Currency Formatting:**
- Use `Double.formattedAsCurrency()` extension from `ExpenseTrackerApp/Utils/Extensions/Double+Currency.swift`
- Default currency code is "USD"

---

*Convention analysis: 2026-04-05*

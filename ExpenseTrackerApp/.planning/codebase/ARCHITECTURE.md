# ARCHITECTURE.md — System Design and Patterns

**Generated:** 2026-04-05
**Codebase:** ExpenseTrackerApp (Swift/SwiftUI iOS)

---

## 1. Architectural Pattern: MVVM

The app follows **Model-View-ViewModel** with a shared service layer:

```
Views (SwiftUI)
  └─ observe @StateObject ViewModels
       └─ depend on DataService (singleton, @EnvironmentObject)
            └─ manages Models (structs)
```

### Layer Boundaries

| Layer | Files | Responsibility |
|-------|-------|----------------|
| **Views** | `Views/**/*.swift` | Declarative UI, user interaction capture |
| **ViewModels** | `ViewModels/**/*.swift` | Business logic, state transformation, service coordination |
| **Services** | `Services/DataService.swift` | Data storage, CRUD, computed aggregates |
| **Models** | `Models/**/*.swift` | Data structures, validation helpers |
| **Utils** | `Utils/**/*.swift` | Shared extensions, constants |

---

## 2. Data Flow

### 2.1 App Initialization

```
ExpenseTrackerAppApp (@main)
  ├─ @StateObject DataService.shared
  ├─ inject via .environmentObject(dataService)
  └─ renders MainTabView
```

**Entry point:** `ExpenseTrackerAppApp.swift` — creates the singleton `DataService` and injects it into the SwiftUI environment.

### 2.2 View → ViewModel → Service Flow

```
View
  ├─ @StateObject viewModel = SomeViewModel()
  │    └─ init(dataService: DataService = .shared)
  │         └─ reads/writes dataService.transactions, .categories
  │
  ├─ observes viewModel.@Published properties
  └─ user action → viewModel.method() → dataService.method()
```

**Key pattern:** ViewModels receive `DataService` via init parameter with default `.shared`. They publish computed display state through `@Published` properties.

### 2.3 Notification-Based Updates

```
DataService.addTransaction()
  ├─ mutates transactions array
  └─ posts Notification.Name.transactionAdded

DashboardViewModel
  └─ subscribes to .transactionAdded in setupBindings()
       └─ calls refreshData() on main queue
            └─ updates @Published totalBalance, recentTransactions, etc.
```

**Notifications defined in** `Constants.swift`:
- `.transactionAdded`
- `.transactionUpdated`
- `.transactionDeleted`

### 2.4 Reactive Filter Pipeline (TransactionViewModel)

```
$searchText ──┐
$selectFilter ├── CombineLatest3 ── debounce(100ms) ── applyFilters()
$selectSort ──┘
```

Search + filter + sort changes are debounced and processed together, producing `filteredTransactions` which feeds `groupedTransactions`.

---

## 3. Key Abstractions

### 3.1 DataService (Singleton)

`DataService.swift` — central in-memory store:

```swift
class DataService: ObservableObject {
    static let shared = DataService()
    @Published var transactions: [Transaction]
    @Published var categories: [Category]
    @Published var userProfile: UserProfile?
    
    // Computed: totalBalance, totalIncomeThisMonth, totalExpensesThisMonth
    // CRUD: addTransaction, updateTransaction, deleteTransaction
}
```

**Limitation:** Concrete class (not protocol). Tight coupling. No testability.

### 3.2 Models (Value Types)

All models are `struct` with `UUID` identifiers:
- `Transaction` — amount (signed), categoryId, date, payee, notes, timestamps
- `Category` — name, icon (SF Symbol), color (hex), isSystem flag
- `UserProfile` — preferences (currency, theme)
- `UserPreferences` — currency code/symbol, AppTheme enum
- `AppTheme` — enum: .light, .dark, .system

### 3.3 ViewModels (Reference Types)

All ViewModels follow the same pattern:
```swift
@MainActor
class SomeViewModel: ObservableObject {
    @Published var /* display state */
    private let dataService: DataService
    private var cancellables = Set<AnyCancellable>()
    
    init(dataService: DataService = .shared) { ... }
}
```

**ViewModels:**
- `DashboardViewModel` — balance, monthly stats, recent transactions
- `TransactionViewModel` — filtering, sorting, search, CRUD delegation
- `SettingsViewModel` — currency/theme via @AppStorage

---

## 4. Navigation Architecture

### 4.1 Tab-Based Navigation

```
MainTabView
  ├─ Tab.dashboard → DashboardView (NavigationStack)
  ├─ Tab.transactions → TransactionsView (NavigationStack)
  ├─ Settings button → SettingsView (sheet)
  └─ FAB → AddTransactionView (sheet)
```

Custom tab bar (`TabBarButton`) renders 2 tabs + settings button + floating add button.

### 4.2 Sheet-Based Flows

- **Add Transaction:** Full-height sheet with form
- **Edit Transaction:** Same sheet, pre-populated from `transactionToEdit`
- **Category Picker:** Medium/large detent sheet
- **Settings:** Full NavigationStack sheet

### 4.3 Delete Flow

```
swipeActions(trailing) → Button(destructive)
  → sets transactionToDelete + showingDeleteConfirmation
  → alert → viewModel.deleteTransaction()
```

---

## 5. State Management

| Mechanism | Usage |
|-----------|-------|
| `@StateObject` | ViewModels owned by views |
| `@Published` | ViewModel → View reactivity |
| `@EnvironmentObject` | DataService injected from app root (not currently used by views directly) |
| `@AppStorage` | Currency, theme persisted to UserDefaults |
| `NotificationCenter` | Cross-ViewModel updates (DataService → DashboardViewModel) |
| `Combine` | Debounced filter pipeline in TransactionViewModel |

---

## 6. Error Handling

**Current state:** Minimal error handling.
- No error states on DataService CRUD operations
- ViewModels have `isLoading` but no `error` property (except TransactionViewModel which declares but never sets it)
- View-layer error handling: alert for delete confirmation
- Form validation: `isValidForm` computed property gates save button

---

## 7. Cross-Cutting Concerns

### 7.1 Theming
- `Color+Theme.swift` defines app color palette
- `AppTheme` enum supports light/dark/system
- Colors use semantic names (`.appPrimary`, `.appSuccess`, `.appDanger`)
- System colors (`.appTextPrimary` = `UIColor.label`) adapt to dark mode automatically

### 7.2 Date Handling
- `Date+Extensions.swift` provides grouping helpers (`isToday`, `isThisWeek`, `isThisMonth`)
- `Transaction.dateGroupTitle` returns section headers for list grouping
- Group order: Today → Yesterday → This Week → This Month → Older

### 7.3 Currency Formatting
- `Double+Currency.swift` — `formattedAsCurrency()` using NumberFormatter
- `Transaction.formattedAmount` and `displayAmount` for UI display
- User's selected currency from SettingsViewModel stored in @AppStorage

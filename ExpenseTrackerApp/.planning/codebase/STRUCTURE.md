# STRUCTURE.md — Directory Layout and Key Locations

**Generated:** 2026-04-05
**Codebase:** ExpenseTrackerApp (Swift/SwiftUI iOS)

---

## 1. Directory Tree

```
ExpenseTrackerApp/
├── ExpenseTrackerAppApp.swift                  # @main entry point
├── Models/
│   ├── Transaction.swift                       # Transaction struct + date grouping
│   ├── Category.swift                          # Category struct + 12 defaults
│   └── UserProfile.swift                       # UserProfile, UserPreferences, AppTheme
├── ViewModels/
│   ├── DashboardViewModel.swift                # Balance, monthly stats, recent txns
│   ├── TransactionViewModel.swift              # Filtering, sorting, search, CRUD
│   └── SettingsViewModel.swift                 # Currency & theme via @AppStorage
├── Views/
│   ├── MainTabView.swift                       # 2-tab layout + FAB + settings
│   ├── Dashboard/
│   │   └── DashboardView.swift                 # Balance card, monthly summary, recent list
│   ├── Transactions/
│   │   ├── TransactionsView.swift              # Date-grouped list, search, filter
│   │   └── AddTransactionView.swift            # Add/edit form + CategoryPickerSheet
│   ├── Settings/
│   │   ├── SettingsView.swift                  # Currency + theme + logout
│   │   ├── CurrencyPickerView.swift            # Currency selection list
│   │   └── ThemeSelectionView.swift            # Theme picker (Light/Dark/System)
│   └── Components/
│       ├── CategoryPickerGrid.swift            # Category grid + CategoryIconView
│       ├── TransactionRow.swift                # Transaction list row
│       └── QuickActionButton.swift             # QuickActionButton, FloatingAddButton
├── Services/
│   └── DataService.swift                       # In-memory store, CRUD, computed totals
└── Utils/
    ├── Constants.swift                         # Layout values, notification names
    └── Extensions/
        ├── Color+Theme.swift                   # Hex init, app color palette
        ├── Date+Extensions.swift                # Date helpers, formatting
        └── Double+Currency.swift                # Currency formatting
```

**Supporting files:**
```
docs/
├── SRS.md                                      # Software Requirements Specification v3.0
└── REMOVED_FEATURES.md                         # Removed features documentation

ExpenseTrackerAppTests/
└── ExpenseTrackerAppTests.swift                # Empty boilerplate

ExpenseTrackerAppUITests/
├── ExpenseTrackerAppUITests.swift
└── ExpenseTrackerAppUITestsLaunchTests.swift
```

---

## 2. Directory Purposes

| Directory | Purpose | File Count |
|-----------|---------|------------|
| `Models/` | Data structures with validation helpers | 3 |
| `ViewModels/` | @MainActor ObservableObjects with business logic | 3 |
| `Views/` | SwiftUI views organized by feature | 9 |
| `Views/Components/` | Reusable UI components | 3 |
| `Services/` | Data storage layer | 1 |
| `Utils/` | Extensions, constants, shared utilities | 4 |

**Total Swift files:** ~20 app source files

---

## 3. Key File Locations (Quick Reference)

### "Where is X?"

| What | File | Line |
|------|------|------|
| App entry point | `ExpenseTrackerAppApp.swift` | 11 |
| Data store (CRUD) | `Services/DataService.swift` | 12 |
| Default categories | `Models/Category.swift` | 62 |
| Transaction amount logic | `Models/Transaction.swift` | 46-62 |
| Date grouping logic | `Models/Transaction.swift` | 86-121 |
| Tab navigation | `Views/MainTabView.swift` | 34 |
| FAB button | `Views/Components/QuickActionButton.swift` | 65 |
| Filter/sort pipeline | `ViewModels/TransactionViewModel.swift` | 94-101 |
| Notification names | `Utils/Constants.swift` | 62-65 |
| App colors | `Utils/Extensions/Color+Theme.swift` | 54-70 |
| Currency formatting | `Utils/Extensions/Double+Currency.swift` | 11-16 |
| Add transaction form | `Views/Transactions/AddTransactionView.swift` | 10 |
| Dashboard layout | `Views/Dashboard/DashboardView.swift` | 15 |
| Settings (currency/theme) | `Views/Settings/SettingsView.swift` | 10 |

---

## 4. Naming Conventions

### 4.1 Files
- **Models:** Singular noun — `Transaction.swift`, `Category.swift`
- **ViewModels:** `<Feature>ViewModel.swift` — `DashboardViewModel.swift`
- **Views:** `<Feature>View.swift` — `DashboardView.swift`, `AddTransactionView.swift`
- **Extensions:** `<Type>+<Purpose>.swift` — `Color+Theme.swift`, `Date+Extensions.swift`

### 4.2 Swift Types
- **Structs:** Models (`Transaction`, `Category`, `UserProfile`)
- **Classes:** ViewModels, DataService (reference types with `ObservableObject`)
- **Enums:** `AppTheme`, `TransactionFilter`, `TransactionSort`, `MainTabView.Tab`

### 4.3 Patterns
- ViewModel init: `init(dataService: DataService = .shared)`
- View init: `@StateObject private var viewModel = SomeViewModel()`
- MARK comments: `// MARK: - Section Name`

---

## 5. Guidance for Adding New Code

### Adding a new model:
1. Create `Models/<ModelName>.swift` as a `struct: Identifiable, Codable, Hashable`
2. Add UUID `id` field
3. If displayed in lists, ensure `==` and `hash(into:)` implementations

### Adding a new ViewModel:
1. Create `ViewModels/<Feature>ViewModel.swift`
2. Mark as `@MainActor class <Name>: ObservableObject`
3. Use `@Published` for reactive state
4. Accept `DataService` via init with `= .shared` default
5. Set up notification bindings in `setupBindings()`

### Adding a new view:
1. Determine location: feature folder or Components
2. Use `@StateObject` for owned ViewModels
3. Use theme colors from `Color+Theme.swift` (never hardcode hex)
4. Use layout constants from `Constants.Layout.*`

### Adding a new extension:
1. Create `Utils/Extensions/<Type>+<Purpose>.swift`
2. Keep formatter instances `static` for performance

### Adding new categories:
1. Edit `Category.defaultCategories` in `Models/Category.swift`
2. Update SRS category table to match

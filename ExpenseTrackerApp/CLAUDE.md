# CLAUDE.md

## Project Overview

Simple SwiftUI iOS app for adding and recording daily transactions (income/expenses). Focus is quick transaction entry and reliable record-keeping. Uses MVVM architecture with an in-memory data service. No persistence yet.

**Scope: Transaction recording only.** No budgets, goals, recurring transactions, or multi-account management.

## Build & Run

```bash
# Build
xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Test
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

> In Xcode: Cmd+B to build, Cmd+U to test.

## Project Structure

```
ExpenseTrackerApp/
├── ExpenseTrackerAppApp.swift           # @main entry — injects DataService as @EnvironmentObject
├── Models/
│   ├── Transaction.swift                # Amount: +income, -expense; date grouping helpers
│   ├── Category.swift                   # 12 built-in categories with icons/colors
│   └── UserProfile.swift               # Theme & currency preferences
├── ViewModels/                          # All @MainActor ObservableObject
│   ├── DashboardViewModel.swift         # Balance, income, expenses, recent transactions
│   ├── TransactionViewModel.swift       # Filtering (all/income/expense), sorting, search
│   └── SettingsViewModel.swift          # Currency & theme management
├── Views/
│   ├── MainTabView.swift                # 2 tabs: Dashboard, Transactions + FAB
│   ├── Dashboard/DashboardView.swift
│   ├── Transactions/
│   │   ├── TransactionsView.swift       # Date-grouped list with search & filter
│   │   └── AddTransactionView.swift     # Add/edit transaction sheet
│   ├── Settings/
│   │   ├── SettingsView.swift           # Currency & theme
│   │   ├── CurrencyPickerView.swift     # Currency selection
│   │   └── ThemeSelectionView.swift     # Theme selection
│   └── Components/
│       ├── CategoryPickerGrid.swift     # Category selection grid
│       ├── TransactionRow.swift         # Transaction list item
│       └── QuickActionButton.swift      # Quick action buttons & FAB
├── Services/
│   └── DataService.swift               # Data store — CRUD, computed totals
└── Utils/
    ├── Constants.swift                  # Layout values, Notification.Name extensions
    └── Extensions/
        ├── Color+Theme.swift            # App colors, hex init
        ├── Date+Extensions.swift        # startOfMonth, isThisMonth, dateGroupTitle
        └── Double+Currency.swift        # Currency formatting helpers
```

## Architecture

### Data Flow

1. **App entry** (`ExpenseTrackerAppApp`): creates data service as `@StateObject`, injects via `.environmentObject()`
2. **ViewModels**: receive data service via `@EnvironmentObject`; own `@Published` display state
3. **Views**: observe `@StateObject` ViewModels

### Data Service

Central in-memory store for `transactions`, `categories`, and `userProfile`.

Key behaviors:
- CRUD operations on transactions
- Computed totals: `totalBalance`, `totalIncomeThisMonth`, `totalExpensesThisMonth`
- `groupedTransactions()` returns date-grouped list

### Notification-Based Updates

Defined in `Constants.swift` as `Notification.Name` extensions:

| Notification | Trigger |
|---|---|
| `transactionAdded` | New transaction created |
| `transactionUpdated` | Transaction edited |
| `transactionDeleted` | Transaction removed |

ViewModels listen to these and recalculate `@Published` properties.

## Coding Conventions

- **SwiftUI + Combine**: use `@Published` for reactive state; no external dependencies
- **Models**: structs with `UUID` ids, `categoryId` reference on Transaction
- **ViewModels**: `@MainActor`, `ObservableObject`, receive data service from environment
- **Colors**: use theme colors from `Color+Theme.swift` (`Color.appPrimary`, `Color.appSuccess`, etc.), never hardcode hex in views
- **Layout constants**: use `Constants.Layout.*` and `Constants.Animation.*`, avoid magic numbers
- **Date formatting**: use `Date+Extensions` helpers, keep formatters static for performance

## Key Model Semantics

- **Transaction.amount**: positive = income, negative = expense
- **Category**: 12 built-in categories; `isSystem` flag marks non-deletable ones (Income, Transfer)
- **Single balance**: all transactions tracked against one total — no multi-account

## Out of Scope (Do NOT Implement)

These features were removed from scope. Do not add unless explicitly requested:
- Budget management
- Goal tracking
- Recurring transactions
- Multi-account management or transfers
- Biometric authentication
- Data export

## SRS Document

Full requirements: `docs/SRS.md`

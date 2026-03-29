# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SwiftUI expense tracking iOS application using MVVM architecture with MockDataService as the shared data store.

## Build Commands

```bash
# Build the project (Cmd+B in Xcode)
xcodebuild -scheme ExpenseTrackerApp

# Run tests
xcodebuild test -scheme ExpenseTrackerApp

# Run specific test target
xcodebuild test -scheme ExpenseTrackerApp -only-destination ExpensesTrackerAppTests

## Project Structure

```
ExpenseTrackerApp/
├── Models/           # Data models (Transaction, Budget, Account, Category, Goal, RecurringTransaction, UserProfile)
├── ViewModels/      # @MainActor ObservableObjects (TransactionViewModel, BudgetViewModel, AccountViewModel, DashboardViewModel, SettingsViewModel)
├── Views/
│   ├── Dashboard/   # Home screen
│   ├── Transactions/ # Add/edit transactions
│   ├── Budget/      # Budget tracking
│   ├── Accounts/    # Account management
│   ├── Settings/    # App settings
│   ├── Components/  # Shared UI components
│   └── MainTabView.swift
├── Services/
│   └── MockDataService.swift  # Singleton data store
├── Utils/
    ├── Constants.swift
    └── Extensions/
        ├── Color+Theme.swift    # Theme colors
        ├── Date+Extensions.swift  # Date helpers
        └── Double+Currency.swift  # Currency formatting
└── ExpenseTrackerAppApp.swift  # App entry point

## Architecture Patterns

### Data Flow
1. **App Entry**: `ExpenseTrackerAppApp` initializes `MockDataService.shared` and injects it into the environment
2. **ViewModels**: Access data via `MockDataService`, apply filtering/sorting, and post notifications
3. **Views**: Observe `@StateObject` ViewModels or get `MockDataService` from `@EnvironmentObject`

### MockDataService (Singleton)
- Central data store for all mock data (accounts, categories, transactions, budgets, goals)
- Provides CRUD operations that update account balances
- Posts `NotificationCenter` events for data changes (`transactionAdded`, `transactionDeleted`, `budgetUpdated`, `accountBalanceChanged`)

### Notification-Based Updates
When data changes, ViewModels listen to notifications and recalculate:
- Transaction changes → `BudgetViewModel.recalculateSpending()`
- Account changes → `DashboardViewModel` updates totals

## Key Implementation Details

### Transaction Model
- Amount: Positive = income, negative = expense
- Uses `categoryId` and `accountId` references
- Date grouping: "Today", "Yesterday", "This Week", "This Month"

### Budget Model
- Supports overall budget (no categoryId) and category budgets
- Has rollover feature with `rolloverAmount`
- Computes `effectiveBudget = amount + rolloverAmount`
- Status colors: Green (<75%), Orange (75-90%), Red (>90%)

### Theme System
- Custom colors defined in `Color+Theme.swift` (`appPrimary`, `appSecondary`, `appSuccess`, `appWarning`, `appDanger`)
- Category-specific colors (`categoryFood`, `categoryTransport`, etc.)
- Access via `Color(hex: "#RRGGBB")` initializer

## Current Development Notes

- Budget feature implementation is progress documented in `EXPENSE_TRACKER_PLAN.md`
- Budget CRUD operations with month navigation are underway
- Spending calculation from transactions is being implemented

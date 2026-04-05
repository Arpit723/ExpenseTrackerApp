# Removed Features (SRS v2.0)

This document tracks features that existed in the codebase but were **removed** to align with the simplified SRS v2.0 scope (transaction recording only).

**Date:** April 4, 2026

---

## Completely Removed Features

### 1. Budget Management
- **What was removed**: Full budget CRUD with monthly/category budgets, progress tracking, and budget alerts
- **Files deleted**: `Models/Budget.swift`, `Models/BudgetError.swift`, `Views/Budget/BudgetView.swift`, `Views/Budget/AddBudgetView.swift`, `Views/Budget/EditBudgetView.swift`, `ViewModels/BudgetViewModel.swift`, `Views/Components/BudgetProgressCard.swift`
- **SRS reference**: Listed under "Future Scope" (Medium priority)
- **Reason**: Out of scope for v2.0 — app focuses on transaction recording only

### 2. Multi-Account Management
- **What was removed**: Multiple accounts (checking, savings, credit cards, cash, investment), account CRUD, account detail view, transfer between accounts
- **Files deleted**: `Models/Account.swift`, `Views/Accounts/AccountsView.swift`, `Views/Accounts/AccountDetailView.swift`, `Views/Accounts/AddEditAccountView.swift`, `Views/Accounts/TransferView.swift`, `ViewModels/AccountViewModel.swift`, `Views/Components/AccountCard.swift`
- **SRS reference**: Section 2.4 Constraints — "Single account — all transactions tracked against one balance"
- **Reason**: SRS v2.0 uses a single balance for all transactions

### 3. Recurring Transactions
- **What was removed**: Recurring transaction scheduling, upcoming bills tracking, recurring transaction display
- **Files deleted**: `Models/RecurringTransaction.swift`, `Views/Components/RecurringTransactionRow.swift`
- **Removed from**: DashboardView ("Upcoming Bills" section), DashboardViewModel, Transaction model (`isRecurring` field)
- **SRS reference**: Listed under "Future Scope" (Low priority)
- **Reason**: Out of scope for v2.0

### 4. Goals / Goal Tracking
- **What was removed**: Financial goals with target amounts, deadlines, and progress tracking
- **Files deleted**: `Models/Goal.swift`, `Views/Components/GoalCard.swift`
- **SRS reference**: Not mentioned in SRS v2.0
- **Reason**: Out of scope for v2.0

### 5. User Profile / Authentication
- **What was removed**: User profile with name, email, avatar, sign out, delete account functionality
- **Files deleted**: `Views/Settings/EditProfileView.swift`
- **Removed from**: SettingsView (profile section, sign out, delete account), UserProfile model (simplified)
- **SRS reference**: Section 2.4 Constraints — "Single-user application (no authentication)"
- **Reason**: No authentication in v2.0

### 6. Notifications System
- **What was removed**: Daily reminders, budget alerts, bill reminders, weekly summaries, goal achievement notifications
- **Removed from**: SettingsView (notifications section), SettingsViewModel, UserProfile model (`NotificationSettings` struct)
- **SRS reference**: Not mentioned in SRS v2.0
- **Reason**: Out of scope for v2.0

### 7. Security / Biometrics
- **What was removed**: Face ID/Touch ID toggle, passcode management
- **Removed from**: SettingsView (security section), SettingsViewModel (`biometricEnabled`)
- **SRS reference**: Listed in CLAUDE.md "Out of Scope" — "Biometric authentication"
- **Reason**: Out of scope for v2.0

### 8. Data Export
- **What was removed**: CSV export of accounts and transactions
- **Removed from**: SettingsView (danger zone section), SettingsViewModel (`exportData()`)
- **SRS reference**: Listed in CLAUDE.md "Out of Scope" — "Data export"
- **Reason**: Out of scope for v2.0

---

## Simplified Features

### Transaction Model
| Removed Field | Reason |
|---|---|
| `accountId` | No multi-account — single balance |
| `tags` | Not in SRS v2.0 |
| `receiptUrl` | Not in SRS v2.0 |
| `isRecurring` | No recurring transactions |
| `location` | Not in SRS v2.0 |

### Category Model
| Removed Field | Reason |
|---|---|
| `parentId` | No category hierarchy in SRS v2.0 |
| `budget` | No budget management |

### Categories Removed
| Old Category | Reason |
|---|---|
| Personal Care | Consolidated — not in SRS v2.0's 12 categories |
| Gifts & Donations | Consolidated — not in SRS v2.0's 12 categories |

### Category Name/Icon Changes
| Old | New |
|---|---|
| Food & Drinks (`fork.knife`) | Food & Dining (`fork.knife`) |
| Healthcare (`cross.case.fill`) | Health (`heart.fill`) |
| Entertainment (`film.fill`) | Entertainment (`gamecontroller.fill`) |
| Bills & Utilities (`bolt.fill`) | Bills & Utilities (`doc.text.fill`) |
| Other (`questionmark.circle`) | Other (`square.grid.2x2.fill`) |

### Dashboard Changes
| Removed Section | Replaced With |
|---|---|
| Net Worth badge | Removed (single balance only) |
| Budget Progress bar | Removed |
| Quick Actions (Budget, Accounts) | Single "Add" action only |
| Today's Spending (5 items) | Recent Transactions (last 10) |
| Upcoming Bills | Removed entirely |

### Navigation Changes
| Old | New |
|---|---|
| 5 tabs (Dashboard, Transactions, Budget, Accounts, Settings) | 2 tabs (Dashboard, Transactions) + Settings accessible from toolbar |

### Settings Changes
| Old | New |
|---|---|
| Profile, Preferences, Notifications, Security, Support, About, Danger Zone | Currency selection + Theme selection only |

### Service Layer
| Old | New |
|---|---|
| `MockDataService` with mock accounts, budgets, goals, recurring data | `DataService` — simple in-memory store for transactions, categories, user profile |

---

## Files Deleted (19 total)

```
Models/Account.swift
Models/Budget.swift
Models/BudgetError.swift
Models/Goal.swift
Models/RecurringTransaction.swift
Views/Budget/BudgetView.swift
Views/Budget/AddBudgetView.swift
Views/Budget/EditBudgetView.swift
Views/Accounts/AccountsView.swift
Views/Accounts/AccountDetailView.swift
Views/Accounts/AddEditAccountView.swift
Views/Accounts/TransferView.swift
Views/Settings/EditProfileView.swift
Views/Components/AccountCard.swift
Views/Components/BudgetProgressCard.swift
Views/Components/RecurringTransactionRow.swift
Views/Components/GoalCard.swift
ViewModels/BudgetViewModel.swift
ViewModels/AccountViewModel.swift
```

---

*This document serves as a reference for what was removed and why, per SRS v2.0.*

# Software Requirements Specification (SRS)

## ExpenseTrackerApp — iOS Transaction Recording Application

**Version:** 3.0
**Date:** April 4, 2026
**Author:** Arpit Parekh
**Status:** Draft

---

## 1. Introduction

### 1.1 Purpose

This document defines the software requirements for **ExpenseTrackerApp**, a simple iOS application for adding and recording daily financial transactions with user authentication via Firebase. It serves as the single source of truth for all features, behaviors, and design decisions.

### 1.2 Scope

ExpenseTrackerApp is a lightweight iOS app that lets users **register an account, log in, add daily income and expense transactions, view transaction history, and persist data via Firebase**. The focus is on simplicity — quick transaction entry and reliable record-keeping. The app does NOT include budget management, goal tracking, recurring transactions, or multi-account management.

### 1.3 Intended Audience

- **Developers**: Implementation reference for current and future contributors
- **Testers**: Basis for test case derivation and validation

### 1.4 Definitions and Acronyms

| Term | Definition |
|------|-----------|
| MVVM | Model-View-ViewModel architectural pattern |
| CRUD | Create, Read, Update, Delete operations |
| SRS | Software Requirements Specification |
| Firebase | Google's mobile/web development platform used for backend services |
| Firestore | Firebase's NoSQL cloud database |
| FirebaseAuth | Firebase Authentication service |

---

## 2. Overall Description

### 2.1 Product Perspective

ExpenseTrackerApp is a standalone iOS application backed by **Firebase**. User authentication is handled via Firebase Auth (Email/Password), and transaction data is stored in Cloud Firestore scoped per user. The application is designed to be simple and focused — users log in, add a transaction, and move on.

### 2.2 Product Functions

The application provides four core functions:

1. **Authentication** — User registration and login via Firebase Auth (Email/Password)
2. **Dashboard** — At-a-glance summary of total balance, monthly income/expenses, and recent transactions
3. **Transaction Management** — Add, view, edit, and delete income and expense transactions with categories
4. **Settings** — Currency selection, theme preference, and logout

### 2.3 User Characteristics

- **Primary User**: Individuals who want a simple way to record daily spending and income
- **Technical Literacy**: General smartphone users; no financial expertise required
- **Usage Pattern**: Quick daily interaction — open, add transaction, close

### 2.4 Constraints

- iOS 16.0+ (SwiftUI requirement)
- Built with Swift and SwiftUI (no UIKit or storyboards)
- Firebase backend required (Auth + Firestore)
- User authentication required (Email/Password via Firebase Auth)
- Each user's data is isolated by their Firebase UID
- Single account per user — all transactions tracked against one balance

### 2.5 Assumptions

- All monetary values are in a single user-selected currency
- Users interact with the app primarily on iPhone (portrait orientation)
- All transactions are manually entered

---

## 3. Functional Requirements

### 3.1 Dashboard (FR-1)

#### FR-1.1 Total Balance Display
The system shall display the current total balance (all income minus all expenses).

#### FR-1.2 Monthly Income/Expense Summary
The system shall display total income and total expenses for the current month.

#### FR-1.3 Recent Transactions
The system shall display the most recent transactions (up to 10) with payee, amount, category icon, and date.

#### FR-1.4 Quick Add Action
The system shall provide a prominent button to quickly add a new transaction.

### 3.2 Transaction Management (FR-2)

#### FR-2.1 Create Transaction
The system shall allow users to create a new transaction with the following attributes:
- **Amount** (required, positive for income, negative for expense)
- **Type** (income or expense toggle)
- **Category** (required, selected from predefined list)
- **Date** (defaults to current date and time)
- **Payee** (optional text — who was the transaction with)
- **Notes** (optional text)

#### FR-2.2 View Transactions
The system shall display transactions grouped by date:
- "Today"
- "Yesterday"
- "This Week"
- "This Month"
- "Older"

Each transaction row shall show: category icon, payee or category name, date, and amount (color-coded: green for income, red for expense).

#### FR-2.3 Edit Transaction
The system shall allow users to edit all attributes of an existing transaction. The total balance shall be recalculated accordingly.

#### FR-2.4 Delete Transaction
The system shall allow users to delete a transaction via swipe action. The total balance shall be recalculated accordingly.

#### FR-2.5 Search Transactions
The system shall support text-based search across payee and notes fields.

#### FR-2.6 Filter Transactions
The system shall support filtering by transaction type:
- All
- Income only
- Expense only

### 3.3 Categories (FR-3)

#### FR-3.1 Default Categories
The system shall provide built-in categories for classifying transactions:

| Category | Type | Icon |
|----------|------|------|
| Food & Dining | Expense | fork.knife |
| Transportation | Expense | car.fill |
| Shopping | Expense | bag.fill |
| Entertainment | Expense | gamecontroller.fill |
| Bills & Utilities | Expense | doc.text.fill |
| Health | Expense | heart.fill |
| Education | Expense | book.fill |
| Travel | Expense | airplane |
| Groceries | Expense | cart.fill |
| Other | Expense | square.grid.2x2.fill |
| Income | Income | dollarsign.circle.fill |
| Transfer | System | arrow.left.arrow.right |

#### FR-3.2 Category Colors
Each category shall have a fixed color for consistent visual identification throughout the app.

### 3.4 Settings (FR-4)

#### FR-4.1 Currency Selection
The system shall allow users to select their preferred currency, which affects all monetary displays.

#### FR-4.2 Theme Selection
The system shall support three theme modes:
- Light
- Dark
- System (follows iOS setting)

#### FR-4.3 Logout
The system shall allow users to log out of their account via the Settings screen. Upon logout, the user shall be returned to the Login screen.

### 3.5 Authentication (FR-5)

#### FR-5.1 User Registration
The system shall allow new users to register with:
- **Email** (required, must be a valid email format)
- **Password** (required, minimum 6 characters)

Upon successful registration, the user shall be automatically signed in and directed to the Dashboard.

#### FR-5.2 User Login
The system shall allow existing users to log in with their email and password. Upon successful login, the user shall be directed to the Dashboard with their data loaded from Firestore.

#### FR-5.3 Auth State Persistence
The system shall persist the user's authentication state across app launches using Firebase Auth's built-in persistence. Users shall not need to log in again unless they explicitly sign out.

#### FR-5.4 Password Reset
The system shall allow users to request a password reset email when they cannot log in. A "Forgot Password?" link shall be available on the Login screen.

#### FR-5.5 Auth Error Handling
The system shall display user-friendly error messages for common authentication failures:
- Invalid email format
- Wrong password
- Email already in use (registration)
- Weak password (registration)
- Network errors

#### FR-5.6 Data Isolation
All transaction data in Firestore shall be scoped to the authenticated user's UID. Users shall only be able to read and write their own data.

---

## 4. Non-Functional Requirements

### 4.1 Performance (NFR-1)

| ID | Requirement |
|----|------------|
| NFR-1.1 | The application shall launch and display the dashboard within 2 seconds |
| NFR-1.2 | Transaction list scrolling shall maintain 60 fps with up to 1,000 transactions |
| NFR-1.3 | Search and filter operations shall return results within 200 ms |

### 4.2 Usability (NFR-2)

| ID | Requirement |
|----|------------|
| NFR-2.1 | Adding a transaction shall be possible within 3 taps from the main screen |
| NFR-2.2 | The interface shall use standard iOS interaction patterns (swipe-to-delete, pull-to-refresh) |
| NFR-2.3 | Amounts shall be formatted according to the user's selected currency |
| NFR-2.4 | Income amounts shall display in green; expense amounts in red |

### 4.3 Reliability (NFR-3)

| ID | Requirement |
|----|------------|
| NFR-3.1 | The application shall not crash on invalid user input |
| NFR-3.2 | Transaction data shall persist across app launches and device restarts |
| NFR-3.3 | The application shall handle empty data states with informative placeholders |

### 4.4 Compatibility (NFR-4)

| ID | Requirement |
|----|------------|
| NFR-4.1 | The application shall run on iOS 16.0 and later |
| NFR-4.2 | The application shall support iPhone form factors |
| NFR-4.3 | The application shall support both light and dark appearance modes |

### 4.5 Maintainability (NFR-5)

| ID | Requirement |
|----|------------|
| NFR-5.1 | The codebase shall follow the MVVM pattern with strict separation of concerns |
| NFR-5.2 | All view models shall be `@MainActor` observable objects |
| NFR-5.3 | Data access shall be abstracted through a service layer to enable future persistence |
| NFR-5.4 | Auth and data services shall be defined as protocols to support dependency injection and mocking in tests |

### 4.6 Security (NFR-6)

| ID | Requirement |
|----|------------|
| NFR-6.1 | All Firestore reads/writes shall be scoped to the authenticated user's UID |
| NFR-6.2 | Firestore Security Rules shall enforce that users can only access their own data |
| NFR-6.3 | Passwords shall never be stored locally — Firebase Auth handles credential management |
| NFR-6.4 | Auth tokens shall be managed by Firebase Auth SDK — not stored in UserDefaults |

---

## 5. Data Requirements

### 5.1 Entity Relationship

```
UserProfile
    │
    ├── Transaction (1:N)
    │       └── Category (N:1)
    │
    └── Category (1:N)
```

### 5.2 Transaction Model

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| amount | Double | Yes | Transaction amount (+income, -expense) |
| categoryId | UUID | Yes | Reference to category |
| date | Date | Yes | Transaction date (defaults to now) |
| payee | String? | No | Who the transaction was with |
| notes | String? | No | Additional notes |
| createdAt | Date | Yes | Record creation timestamp |
| updatedAt | Date? | No | Last modification timestamp |

### 5.3 Data Persistence

| Version | Storage Mechanism |
|---------|------------------|
| Current (v3.0) | **Firebase Firestore** — cloud-hosted NoSQL database, scoped per user UID |
| Collections | `users/{uid}/transactions` — transaction documents |
| | `users/{uid}/profile` — user profile document |

### 5.4 Firebase Firestore Schema

#### transactions collection (`users/{uid}/transactions/{transactionId}`)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | UUID as string |
| amount | Double | Yes | Transaction amount (+income, -expense) |
| categoryId | String | Yes | UUID of category as string |
| date | Timestamp | Yes | Transaction date |
| payee | String | No | Who the transaction was with |
| notes | String | No | Additional notes |
| createdAt | Timestamp | Yes | Record creation timestamp |
| updatedAt | Timestamp | No | Last modification timestamp |

### 5.5 Data Integrity Rules

| Rule | Description |
|------|-------------|
| DR-1 | Transaction amount must be non-zero |
| DR-2 | Transaction date must not be in the future beyond current date |
| DR-3 | Category must exist when creating a transaction |
| DR-4 | All Firestore writes must include the authenticated user's UID |
| DR-5 | Firestore Security Rules must validate that request.auth.uid matches the document path UID |

---

## 6. User Interface Requirements

### 6.1 Navigation Structure

The application uses an **auth-gated two-tab** navigation:

**Unauthenticated state:**
- Login View (default)
- Register View (navigable from Login)

**Authenticated state:**

| Tab | Label | Primary View |
|-----|-------|-------------|
| 1 | Dashboard | Balance overview, recent transactions |
| 2 | Transactions | Full transaction list, add/edit |

A floating action button (FAB) shall be available for quick transaction creation.

### 6.2 Color Theme

| Element | Color | Hex |
|---------|-------|-----|
| Primary | App Blue | `#007AFF` |
| Success/Income | Green | `#34C759` |
| Danger/Expense | Red | `#FF3B30` |
| Background | System | `#F2F2F7` (light) / `#1C1C1E` (dark) |

### 6.3 Screen Specifications

#### 6.3.1 Dashboard Screen
- Total balance card with currency symbol
- Monthly income/expense summary
- Recent transactions list (last 10)
- Floating "Add Transaction" button

#### 6.3.2 Transaction List Screen
- Filter tabs at top (All / Income / Expenses)
- Search bar
- Date-grouped transaction list
- Swipe actions: Edit (leading), Delete (trailing)
- Empty state with call-to-action when no transactions exist

#### 6.3.3 Add/Edit Transaction Sheet
- Amount input
- Income/Expense toggle
- Category picker (grid of icons with labels)
- Date picker
- Payee text field
- Notes text field
- Save/Cancel buttons

#### 6.3.4 Settings Screen
- Currency picker
- Theme selector (Light / Dark / System)
- Logout button (signs out of Firebase Auth)

#### 6.3.5 Login Screen
- Email text field with validation
- Password text field (secure entry)
- "Login" button
- "Forgot Password?" link (triggers Firebase password reset email)
- "Don't have an account? Register" link (navigates to Register screen)
- Error message display area

#### 6.3.6 Register Screen
- Email text field with validation
- Password text field (secure entry)
- Confirm password text field (secure entry)
- "Register" button
- "Already have an account? Login" link (navigates back to Login screen)
- Error message display area

---

## 7. System Architecture

### 7.1 Architectural Pattern: MVVM with Firebase Backend

```
┌─────────────────────────────────────────────────────┐
│                        Views                         │
│  (SwiftUI — observes @StateObject ViewModels)       │
│  LoginView │ RegisterView │ Dashboard │ Transactions│
└──────────────┬──────────────────────────┬───────────┘
               │                          │
               ▼                          ▼
┌────────────────────────┐  ┌─────────────────────────┐
│     AuthViewModel      │  │  DashboardViewModel     │
│     TransactionVM      │  │  TransactionViewModel   │
│  @MainActor            │  │  @MainActor             │
│  @Published properties │  │  @Published properties  │
└──────────┬─────────────┘  └──────────┬──────────────┘
           │                           │
           ▼                           ▼
┌──────────────────┐    ┌─────────────────────────┐
│   AuthService    │    │     DataService          │
│  Firebase Auth   │    │  Firebase Firestore      │
│  signIn/signUp   │    │  CRUD operations         │
│  signOut         │    │  Computed totals          │
│  Auth state      │    │  Real-time listeners     │
└──────────────────┘    └─────────────────────────┘
           │                           │
           ▼                           ▼
              ┌──────────────────────────┐
              │      Firebase             │
              │  Auth + Firestore         │
              └──────────────────────────┘
                           │
                           ▼
               ┌─────────────────────┐
               │      Models         │
               │  Transaction        │
               │  Category           │
               │  UserProfile        │
               └─────────────────────┘
```

### 7.2 Component Responsibilities

| Component | Responsibility |
|-----------|---------------|
| **Views** | Render UI, capture user input, observe ViewModel state |
| **ViewModels** | Transform data for display, handle user actions, coordinate with services |
| **AuthService** | Handle Firebase Auth operations (signIn, signUp, signOut, password reset, auth state) |
| **DataService** | Store and retrieve transactions and categories via Firestore, compute totals |
| **Models** | Define data structures (Transaction, Category, UserProfile) |
| **Extensions** | Shared formatting (currency, date, color) and constants |

---

## 8. Assumptions and Dependencies

### 8.1 Assumptions

1. The user has an iOS device running iOS 16.0 or later
2. All transactions are manually entered (no automatic bank feed)
3. A single currency applies to all transactions
4. One balance tracks all transactions (no multi-account)
5. Users have internet connectivity for Firebase Auth and Firestore access

### 8.2 Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| SwiftUI | iOS 16+ | UI framework |
| Foundation | — | Core Swift libraries |
| Combine | — | Reactive programming |
| Firebase Auth | Latest (SPM) | User authentication (Email/Password) |
| Firebase Firestore | Latest (SPM) | Cloud database for transaction storage |
| Firebase Core | Latest (SPM) | Firebase SDK initialization |
| XCTest | — | Unit testing framework |

---

## 9. Unit Testing Requirements

### 9.1 Testing Strategy

The application shall include a comprehensive unit test suite using the **XCTest** framework. Tests shall be organized in a test target `ExpenseTrackerAppTests` that mirrors the app's module structure.

### 9.2 Test Scope

#### 9.2.1 Model Tests (FR-6.1)

| Test Area | Description |
|-----------|-------------|
| Transaction model | Verify amount sign conventions (+income, -expense), date grouping helpers, UUID generation |
| Category model | Verify all 12 default categories exist, `isSystem` flags, icon/color assignments |
| UserProfile model | Verify default values, theme enum cases, currency codes |

#### 9.2.2 ViewModel Tests (FR-6.2)

| Test Area | Description |
|-----------|-------------|
| AuthViewModel | Test login success/failure, registration success/failure, sign out, password reset, auth state changes |
| DashboardViewModel | Test balance calculation, monthly income/expense totals, recent transactions limit |
| TransactionViewModel | Test filtering (all/income/expense), sorting (by date/amount), search functionality, empty states |

#### 9.2.3 Service Tests (FR-6.3)

| Test Area | Description |
|-----------|-------------|
| AuthService | Test signIn, signUp, signOut, password reset — use protocol-based mocking or Firebase Emulator |
| DataService | Test CRUD operations, computed totals, date grouping — use protocol-based mocking or Firebase Emulator |

### 9.3 Testing Conventions

- Services (`AuthService`, `DataService`) shall be defined as **protocols** with concrete Firebase implementations, enabling mock implementations for unit tests
- All tests shall be independent — no test shall depend on the state created by another test
- Test files shall mirror the app structure under `ExpenseTrackerAppTests/`
- Use `setUp()` and `tearDown()` for test isolation
- Aim for minimum **80% code coverage** on ViewModels and Services

### 9.4 Test File Structure

```
ExpenseTrackerAppTests/
├── ViewModels/
│   ├── AuthViewModelTests.swift
│   ├── DashboardViewModelTests.swift
│   └── TransactionViewModelTests.swift
├── Models/
│   ├── TransactionTests.swift
│   └── CategoryTests.swift
├── Services/
│   ├── MockAuthService.swift
│   ├── MockDataService.swift
│   ├── AuthServiceTests.swift
│   └── DataServiceTests.swift
└── Helpers/
    └── TestDataFactory.swift          # Shared test data builders
```

### 9.5 Test Execution

```bash
# Run all tests
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'

# Run specific test class
xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests/AuthViewModelTests
```

---

## 10. Future Scope

The following features are identified for future development but are **out of scope** for the current version:

| Priority | Feature | Description |
|----------|---------|-------------|
| High | Offline support | Cache Firestore data locally for offline access |
| Medium | Multiple accounts | Separate balances for different accounts |
| Medium | Budget tracking | Set monthly spending limits per category |
| Medium | Charts and analytics | Visual spending trends |
| Low | Recurring transactions | Auto-add scheduled bills |
| Low | Social login | Google, Apple Sign-In authentication |
| Low | Widget support | Quick transaction entry from home screen |

---

## Appendix A: Error Handling

| Scenario | Message | Recovery |
|----------|---------|----------|
| Empty amount on save | "Please enter an amount" | Enter amount |
| No category selected | "Please select a category" | Select a category |
| Delete confirmation | "Delete this transaction?" | Confirm or cancel |
| Invalid email format | "Please enter a valid email address" | Correct email |
| Weak password | "Password must be at least 6 characters" | Enter stronger password |
| Email already in use | "An account with this email already exists" | Log in instead |
| Wrong password | "Incorrect password. Please try again." | Re-enter password |
| User not found | "No account found with this email" | Register a new account |
| Network error | "Unable to connect. Please check your internet connection." | Retry |
| Password reset sent | "Password reset email sent" | Check email inbox |

---

## Appendix B: Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-04 | Arpit Parekh | Initial SRS — full-featured expense tracker |
| 2.0 | 2026-04-04 | Arpit Parekh | Simplified scope to transaction recording only |
| 3.0 | 2026-04-04 | Arpit Parekh | Added Firebase Auth (login/register), Firestore backend, unit testing requirements |

---

*End of Software Requirements Specification*

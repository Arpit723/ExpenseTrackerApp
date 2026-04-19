# Software Requirements Specification (SRS)

## ExpenseTrackerApp — iOS Daily Expense Tracking Application

**Version:** 4.2
**Date:** April 18, 2026
**Author:** Arpit Parekh
**Status:** In Progress

---

## 1. Introduction

### 1.1 Purpose

This document defines the software requirements for **ExpenseTrackerApp**, a simple iOS application for recording daily financial transactions with user authentication and cloud-based data persistence. It serves as the single source of truth for all features, behaviors, and design decisions.

### 1.2 Scope

ExpenseTrackerApp is a lightweight iOS app that lets users **register an account, log in, add daily income and expense transactions, view transaction history, and track spending patterns**. The app uses **Firebase Authentication** (Email/Password) for user authentication and **Firebase Firestore** for per-user cloud data persistence. The focus is on simplicity — quick transaction entry and reliable record-keeping.

The app does NOT include budget management, goal tracking, recurring transactions, or multi-account management.

### 1.3 Intended Audience

- **Developers**: Implementation reference for current and future contributors
- **Testers**: Basis for test case derivation and validation

### 1.4 Definitions and Acronyms

| Term | Definition |
|------|-----------|
| MVVM | Model-View-ViewModel architectural pattern |
| CRUD | Create, Read, Update, Delete operations |
| SRS | Software Requirements Specification |
| Firebase Auth | Google's authentication service for user login/registration |
| Firestore | Firebase's NoSQL cloud database for data persistence |
| Firebase Storage | Firebase's cloud storage for files (receipt photos — deferred to future scope) |
| Alphanumeric | Text containing both alphabetic characters (a-z, A-Z) and numeric digits (0-9) |
| Firestore Subcollection | A nested collection under a parent document (e.g., users/{uid}/transactions) |
| SPM | Swift Package Manager for dependency management |

---

## 2. Overall Description

### 2.1 Product Perspective

ExpenseTrackerApp is a standalone iOS application backed by Firebase services. User authentication is handled by Firebase Auth (Email/Password). Transaction and profile data are persisted per-user in Firebase Firestore. The app uses MVVM architecture with protocol-based services for testability.

### 2.2 Product Functions

The application provides five core functions:

1. **Authentication** — Firebase Auth Email/Password login and registration with form validation
2. **Dashboard** — At-a-glance summary of total balance, today's spending, monthly income/expenses, category spending breakdown, and recent transactions
3. **Transaction Management** — Add, view, edit, and delete income and expense transactions with categories and date grouping
4. **Settings** — Currency selection, theme preference, profile management, daily reminder, sign out, delete account
5. **Firebase Data Persistence** — Transactions and user profile stored per-user in Firestore with offline caching

### 2.3 User Characteristics

- **Primary User**: Individuals who want a simple way to record daily spending and income
- **Technical Literacy**: General smartphone users; no financial expertise required
- **Usage Pattern**: Quick daily interaction — open, add transaction, close

### 2.4 Constraints

- iOS 18.5+ (SwiftUI requirement)
- Built with Swift and SwiftUI (no UIKit or storyboards)
- Firebase backend: Firebase Auth + Firestore (via SPM)
- Multi-user application with Firebase Auth; each user's data scoped by UID
- Single account per user — all transactions tracked against one balance
- Single currency per user — no multi-currency support

### 2.5 Assumptions

- All monetary values are in a single user-selected currency
- Users interact with the app primarily on iPhone (portrait orientation)
- All transactions are manually entered
- Internet connection available for initial login/sync; offline supported via Firestore cache

---

## 3. Functional Requirements

### 3.1 Authentication (FR-1)

#### FR-1.1 Login Screen
The system shall display a Login screen as the first screen on app launch (unauthenticated state).

**Login Screen Fields:**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Email | Text Field | Yes | Must contain "@" and not be empty |
| Password | Secure Field | Yes | Min 6 characters, must be alphanumeric (at least one letter and one digit) |

**Login Screen Elements:**
- Email input with envelope icon, email keyboard, no autocapitalization
- Password input with lock icon and show/hide eye toggle
- "Forgot Password?" link (right-aligned, app primary color) — triggers Firebase password reset email
- "Login" button — gradient fill (disabled until form is valid, shows spinner during authentication)
- "Don't have an account? Sign Up" link — navigates to Register screen
- App logo (gradient circle with dollar sign icon, 80x80pt) and "Expense Tracker" heading

**Firebase Auth Integration:**
- On Login tap: authenticate email/password against Firebase Auth
- Success: transition to MainTabView (home screen)
- Failure: display error alert with user-friendly message mapped from Firebase error codes

#### FR-1.2 Register Screen
The system shall provide a registration screen navigable from the Login screen.

**Register Screen Fields:**

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| Full Name | Text Field | Yes | Non-empty after trimming whitespace |
| Birth Date | Date Picker | Yes | Must not be in the future |
| Email | Text Field | Yes | Must contain "@" |
| Phone Number | Text Field | Yes | Min 7 characters |
| Password | Secure Field | Yes | Min 6 characters, alphanumeric (at least one letter and one digit) |
| Confirm Password | Secure Field | Yes | Must match Password |

**Register Screen Elements:**
- Full Name input with person icon, words autocapitalization
- Birth Date picker with calendar icon, compact DatePicker (max: today)
- Email input with envelope icon, email keyboard, no autocapitalization
- Phone Number input with phone icon, phone pad keyboard
- Password input with lock icon and show/hide toggle, "Min 6 characters" placeholder
- Confirm Password input with lock.rotation icon and show/hide toggle
- Password mismatch hint (red 12pt text) when passwords don't match
- "Sign Up" button — gradient fill (disabled until all fields valid, shows spinner)
- "Already have an account? Login" link — navigates back to Login
- "Login" button in top-right navigation toolbar

**Firebase Auth + Firestore Integration:**
- On Sign Up tap: create user in Firebase Auth
- On success: save user profile to Firestore `users` collection (document ID = Firebase Auth UID)
- Firestore fields: uid (Firebase Auth UID), fullName, birthDate, email, phone, createdAt, updatedAt
- Success: transition to MainTabView (home screen)
- Failure: display error alert (e.g., "Email already in use", "Weak password")

#### FR-1.3 Auth Gate Navigation
The app shall use a root-level auth gate that shows:
- **Unauthenticated**: NavigationStack containing LoginView -> RegisterView
- **Authenticated**: MainTabView (Dashboard + Transactions)

Transition from Login to Register uses `navigationDestination`. Both Login success and Register success set authenticated state to reveal the main app.

#### FR-1.4 Firebase Auth Backend
- **Provider**: Firebase Auth Email/Password
- **Login**: verify credentials against Firebase Auth; on match, grant access
- **Register**: create Firebase Auth user, then store profile in Firestore
- **Session**: observe Firebase Auth state listener for real-time auth state changes
- **Password Reset**: send Firebase password reset email to user's email address
- **Error Handling**: map Firebase error codes to user-friendly messages

#### FR-1.5 Sign Out
- "Sign Out" button in Settings screen (destructive red style, bottom section)
- On tap: confirmation alert "Are you sure you want to sign out?" with Cancel / Sign Out
- On confirm: call Firebase Auth signOut(), clear local in-memory data
- Auth state listener triggers navigation back to Login screen
- All local in-memory transaction data cleared

#### FR-1.6 Delete Account
- "Delete Account" button in Settings screen (destructive red, below Sign Out)
- On tap: confirmation alert with text field "Type DELETE to confirm"
- On confirm: delete Firebase Auth user, delete all Firestore user data (profile + transactions subcollection via batched writes, 500 per batch), clear local state
- Show progress spinner with "Deleting account..." during batch delete
- Firestore subcollections do not cascade delete; each transaction document must be deleted individually in batches
- Navigate to Login screen
- This action is irreversible

#### FR-1.7 Auto-Login (Session Persistence)
- Firebase Auth persists session across app restarts automatically
- On app launch: check Firebase Auth currentUser — if non-nil, go straight to MainTabView
- If nil, show Login screen
- No additional token management needed (Firebase handles refresh tokens)

#### FR-1.8 Firebase Firestore — User Data
- `users` collection, document ID = Firebase Auth UID (primary key)
- Fields: uid (Firebase Auth UID), fullName, birthDate, email, phone, currency, theme, createdAt, updatedAt
- On register: write new user document
- On login: read user document
- On profile edit: update user document


### 3.2 Dashboard (FR-2)

#### FR-2.1 Total Balance Display
The system shall display the current total balance (all income minus all expenses).

#### FR-2.2 Monthly Income/Expense Summary
The system shall display total income and total expenses for the current month.

#### FR-2.3 Today's Spending Total
The system shall display a prominent card showing today's total spending.
- Computed: sum of all expense transactions where date is today
- Updates in real-time when transactions are added, edited, or deleted
- Color-coded: amount displayed in appDanger color for visibility

#### FR-2.4 Recent Transactions
The system shall display the most recent transactions (up to 10) with payee, amount, category icon, and date.

#### FR-2.5 Quick Add Action
The system shall provide a floating action button (FAB) positioned at the bottom-right corner, above the tab bar, for quick transaction creation.

#### FR-2.6 Category Spending Summary
The system shall display a spending breakdown by category for the current month.
- List format: category icon + category name + total amount + percentage of total spending
- Sorted by highest spending first
- Only shows categories with non-zero spending for the current month
- Computed client-side: query current month's transactions from Firestore, then aggregate by category in Swift

#### FR-2.7 Receipt Photo Attachment
*Deferred to future scope. Not implemented in current version.*

The system shall allow users to attach a receipt photo to any transaction.
- Photo picker: camera or photo library
- Photo stored in Firebase Storage at path: `receipts/{uid}/{transactionId}.jpg`
- Transaction document in Firestore gets optional `receiptURL` field (String?)
- Thumbnail shown in transaction edit sheet; tap to view full-size
- Photo compressed to max 1MB before upload
- If photo upload fails, transaction still saves (receipt is optional)

#### FR-2.8 Daily Expense Reminder
The system shall provide a configurable daily reminder notification.
- Local notification sent daily at user-configured time (default: 8:00 PM)
- Notification text: "Don't forget to log your expenses today!"
- Tapping notification opens the app to Add Transaction screen
- Toggle on/off in Settings screen
- Requires user notification permission request on first enable
- Uses UNUserNotificationCenter for scheduling

### 3.3 Transaction Management (FR-3)

#### FR-3.1 Create Transaction
The system shall allow users to create a new transaction with the following attributes:
- **Amount** (required, positive for income, negative for expense)
- **Type** (income or expense toggle)
- **Category** (required, selected from predefined list via grid picker)
- **Date** (defaults to current date and time, not beyond current date)
- **Payee** (optional text — who was the transaction with)
- **Notes** (optional text)
- Quick amount buttons ($5, $10, $20, $50, $100) for fast entry

#### FR-3.2 View Transactions
The system shall display transactions grouped by date:
- "Today"
- "Yesterday"
- "This Week"
- "This Month"
- "Older"

Each transaction row shall show: category icon, payee or category name, date, and amount (color-coded: green for income, red for expense).

#### FR-3.3 Edit Transaction
The system shall allow users to edit all attributes of an existing transaction via the same form used for creation (pre-populated). The total balance shall be recalculated accordingly.

#### FR-3.4 Delete Transaction
The system shall allow users to delete a transaction via swipe action. The total balance shall be recalculated accordingly.

#### FR-3.5 Search Transactions
The system shall support text-based search across payee and notes fields.

#### FR-3.6 Filter Transactions
The system shall support filtering by transaction type:
- All
- Income only
- Expense only

#### FR-3.7 Transaction Firestore Storage
Transactions shall be stored in Firebase Firestore per user.
- Storage path: `users/{uid}/transactions/{transactionId}` (subcollection)
- Each transaction document fields:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String (UUID) | Yes | Unique identifier |
| amount | Double | Yes | Transaction amount (+income, -expense) |
| categoryId | String (UUID) | Yes | Reference to category |
| date | Timestamp | Yes | Transaction date |
| payee | String | No | Who the transaction was with |
| notes | String | No | Additional notes |
| createdAt | Timestamp | Yes | Record creation timestamp |
| updatedAt | Timestamp | Yes | Last modification timestamp |

- CRUD operations sync to Firestore in real-time
- On app launch: load transactions from Firestore for current user
- Offline: Firestore SDK caches locally (default behavior)

#### FR-3.8 Transaction Pagination
- **Dashboard**: loads only the 10 most recent transactions (`limit(10), orderBy date descending`)
- **Transaction List**: uses infinite scroll with 50-item pages, cursor-based pagination
- **Monthly queries**: filtered by `date >= startOfMonth` for income/expense totals and category breakdown
- **Search**: Firestore query with `>=` prefix on payee field, limited to current page


### 3.4 Categories (FR-4)

#### FR-4.1 Default Categories
The system shall provide 12 built-in categories for classifying transactions:

| Category | Type | Icon | Color |
|----------|------|------|-------|
| Food & Dining | Expense | fork.knife | #FF6B6B |
| Transportation | Expense | car.fill | #4ECDC4 |
| Shopping | Expense | bag.fill | #45B7D1 |
| Entertainment | Expense | gamecontroller.fill | #96CEB4 |
| Bills & Utilities | Expense | doc.text.fill | #FFEAA7 |
| Health | Expense | heart.fill | #DDA0DD |
| Education | Expense | book.fill | #98D8C8 |
| Travel | Expense | airplane | #5DADE2 |
| Groceries | Expense | cart.fill | #58D68D |
| Other | Expense | square.grid.2x2.fill | #BDC3C7 |
| Income | Income | dollarsign.circle.fill | #27AE60 |
| Transfer | System | arrow.left.arrow.right | #85929E |

Categories are hardcoded in the app (not stored in Firestore).

#### FR-4.2 Category Colors
Each category shall have a fixed color for consistent visual identification throughout the app.

#### FR-4.3 System Categories
"Income" and "Transfer" categories are flagged as `isSystem: true` and cannot be deleted.

### 3.5 Settings (FR-5)

#### FR-5.1 Currency Selection
The system shall allow users to select their preferred currency, which affects all monetary displays. Persisted via `@AppStorage` (UserDefaults).

#### FR-5.2 Theme Selection
The system shall support three theme modes:
- Light
- Dark
- System (follows iOS setting)

Persisted via `@AppStorage` (UserDefaults).

#### FR-5.3 View Profile
- Profile section at top of Settings screen
- Display: full name, email (read-only), phone number, birth date
- Profile avatar circle with user initials
- Tap profile section to open Edit Profile sheet

#### FR-5.4 Edit Profile
- Edit Profile sheet with fields: Full Name, Phone Number, Birth Date
- Email field shown but read-only (email is Firebase Auth primary key)
- Save button: updates Firestore `users/{uid}` document
- Cancel button: dismiss without saving
- Validation: same rules as registration (name non-empty, phone min 7 chars, birthdate not future)
- Success: update local UserProfile, dismiss sheet

#### FR-5.5 Rate & Review App
- "Rate This App" option in Settings (star icon)
- On tap: triggers `SKStoreReviewController.requestReview()` — Apple's native App Store review prompt
- iOS controls when the prompt actually appears (Apple may suppress if asked too frequently)

#### FR-5.6 Contact Support / Feedback
- "Send Feedback" option in Settings (envelope icon)
- On tap: opens iOS Mail compose sheet pre-filled with:
  - To: developer support email (configurable constant)
  - Subject: "Expense Tracker Feedback"
  - Body: includes app version and iOS version for debugging context
- If Mail not configured on device: show alert with fallback support email address
- Uses MessageUI framework

#### FR-5.7 Sign Out
- "Sign Out" button in Settings screen (destructive red style, bottom section)
- On tap: confirmation alert "Are you sure you want to sign out?" with Cancel / Sign Out
- On confirm: call Firebase Auth signOut(), clear local in-memory data
- Auth state listener triggers navigation back to Login screen

#### FR-5.8 Delete Account
- "Delete Account" button in Settings screen (destructive red, below Sign Out)
- On tap: confirmation alert with text field "Type DELETE to confirm"
- On confirm: delete Firebase Auth user, delete all Firestore data (batch delete transactions subcollection, then user document), clear local state
- Navigate to Login screen
- This action is irreversible

### 3.6 Navigation (FR-6)

#### FR-6.1 Tab-Based Navigation
The application uses a custom tab bar at the bottom with two tabs plus a settings button:

| Position | Label | Icon | Primary View |
|----------|-------|------|-------------|
| Tab 1 | Home | house.fill | Balance overview, today's spending, category summary, recent transactions |
| Tab 2 | Transactions | list.bullet.rectangle | Full transaction list, add/edit |
| Button | Settings | gearshape.fill | Opens as full sheet (not a tab) |

#### FR-6.2 Sheet-Based Flows
- **Add Transaction**: Full-height sheet from FAB or Transaction list
- **Edit Transaction**: Same sheet, pre-populated from selected transaction
- **Category Picker**: Medium/large detent sheet with grid layout
- **Settings**: Full NavigationStack sheet
- **Edit Profile**: Sheet from Settings profile section

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
| NFR-3.2 | The application shall handle empty data states with informative placeholders |
| NFR-3.3 | Firestore offline caching shall allow the app to function without network (read cached data, queue writes) |

### 4.4 Compatibility (NFR-4)

| ID | Requirement |
|----|------------|
| NFR-4.1 | The application shall run on iOS 18.5 and later |
| NFR-4.2 | The application shall support iPhone form factors |
| NFR-4.3 | The application shall support both light and dark appearance modes |

### 4.5 Maintainability (NFR-5)

| ID | Requirement |
|----|------------|
| NFR-5.1 | The codebase shall follow the MVVM pattern with strict separation of concerns |
| NFR-5.2 | All view models shall be `@MainActor` observable objects |
| NFR-5.3 | Data access shall be abstracted through a service layer |
| NFR-5.4 | Services shall be defined as protocols (`AuthServiceProtocol`, `DataServiceProtocol`) to support dependency injection and testability |


---

## 5. Data Requirements

### 5.1 Entity Relationship

```
Firebase Auth User (UID)
    |
    +-- users/{uid} (Firestore Document)
            |
            +-- transactions/{transactionId} (Firestore Subcollection)
                    |
                    +-- references categoryId (hardcoded in app)
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
| updatedAt | Date | Yes | Last modification timestamp |

**Computed Properties:**
- `isExpense`: `amount < 0`
- `isIncome`: `amount > 0`
- `formattedAmount`: Currency-formatted absolute value
- `displayAmount`: Signed display string (e.g., "+$50.00", "-$25.00")
- `amountColor`: Red for expense, green for income
- Date grouping: `isToday`, `isYesterday`, `isThisWeek`, `isThisMonth`, `dateGroupTitle`

### 5.3 Category Model

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| name | String | Yes | Display name |
| icon | String | Yes | SF Symbol name |
| color | String | Yes | Hex color string |
| isSystem | Bool | Yes | Whether category is non-deletable |
| createdAt | Date | Yes | Creation timestamp |
| updatedAt | Date | Yes | Last modification timestamp |

### 5.4 UserProfile Model

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | UUID | Yes | Unique identifier |
| fullName | String | Yes | User's full name |
| birthDate | Date | Yes | User's birth date |
| email | String | Yes | User's email (Firebase Auth identifier) |
| phone | String | Yes | User's phone number |
| preferences | UserPreferences | Yes | Currency, theme settings |
| createdAt | Date | Yes | Creation timestamp |
| updatedAt | Date | Yes | Last modification timestamp |

### 5.5 Data Persistence

| Storage | Mechanism | Data |
|---------|-----------|------|
| Firebase Firestore | `users/{uid}` document | User profile (name, email, phone, birthdate, preferences) |
| Firebase Firestore | `users/{uid}/transactions/{txId}` subcollection | Transactions |
| In-memory | `FirestoreDataService` (replaces DataService.shared) | Local cache of transactions, categories |
| UserDefaults | `@AppStorage` (cache layer, Firestore is source of truth) | Currency selection, Theme preference |

### 5.6 Data Integrity Rules

| Rule | Description |
|------|-------------|
| DR-1 | Transaction amount must be non-zero |
| DR-2 | Transaction date must not be in the future beyond current date |
| DR-3 | Category must exist when creating a transaction |
| DR-4 | Password must be minimum 6 characters |
| DR-5 | Confirm password must match password |
| DR-6 | Email must contain "@" character |
| DR-7 | Password must contain at least one alphabetic character (a-z, A-Z) |
| DR-8 | Password must contain at least one numeric digit (0-9) |
| DR-9 | Phone number must be minimum 7 characters |
| DR-10 | Full name must not be empty after trimming whitespace |
| DR-11 | Birth date must not be in the future |

### 5.7 Firestore Schema

**Collection: `users`**
- Document ID: Firebase Auth UID (primary key)

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| uid | String | Yes | Firebase Auth UID |
| fullName | String | Yes | User's full name |
| birthDate | Timestamp | Yes | User's birth date |
| email | String | Yes | User's email |
| phone | String | Yes | Phone number |
| currency | String | Yes | Currency code (e.g., "USD") |
| theme | String | Yes | AppTheme raw value ("Light", "Dark", "System") |
| createdAt | Timestamp | Yes | Account creation timestamp |
| updatedAt | Timestamp | Yes | Last profile update timestamp |

**Subcollection: `users/{uid}/transactions`**
- Document ID: transaction UUID

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | String | Yes | UUID as string |
| amount | Double | Yes | Signed amount (+income, -expense) |
| categoryId | String | Yes | UUID reference to category |
| date | Timestamp | Yes | Transaction date |
| payee | String | No | Transaction payee (nullable) |
| notes | String | No | Additional notes (nullable) |
| createdAt | Timestamp | Yes | Creation timestamp |
| updatedAt | Timestamp | Yes | Last update timestamp |

### 5.8 Firestore Security Rules

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      // Users can only CRUD their own transactions
      match /transactions/{transactionId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;
      }
    }
  }
}
```

**Security principles:**
- All rules require authentication (`request.auth != null`)
- Users can only read/write their own data (scoped by UID, not email)
- No unauthenticated access to any data
- Transaction subcollection inherits parent document rules

### 5.9 Offline Behavior
- Firestore SDK provides automatic offline caching (no extra code needed)
- Reads return last-cached data when offline
- Writes queue locally and sync when network returns
- No explicit offline indicator UI required

---

## 6. User Interface Requirements

### 6.1 Navigation Structure

The application uses an **auth-gated tab-based** navigation:

**Unauthenticated state:**
- Login View (default)
- Register View (push navigation from Login)

**Authenticated state:**

| Position | Label | Icon | Primary View |
|----------|-------|------|-------------|
| Tab 1 | Home | house.fill | Balance, today's spending, category summary, recent transactions |
| Tab 2 | Transactions | list.bullet.rectangle | Full transaction list, add/edit |
| Button | Settings | gearshape.fill | Opens as sheet |

A floating action button (FAB) at the **bottom-right corner**, above the tab bar, provides quick transaction creation.

### 6.2 Color Theme

| Element | Color | Hex |
|---------|-------|-----|
| Primary | App Blue | `#007AFF` |
| Secondary | Purple | `#5856D6` |
| Success/Income | Green | `#34C759` |
| Warning | Orange | `#FF9500` |
| Danger/Expense | Red | `#FF3B30` |
| Background | System Grouped | `#F2F2F7` (light) / `#1C1C1E` (dark) |
| Card Background | Secondary Grouped | System adaptive |
| Text Primary | Label | System adaptive |
| Text Secondary | Secondary Label | System adaptive |
| Text Tertiary | Tertiary Label | System adaptive |

### 6.3 Layout Constants

| Constant | Value | Usage |
|----------|-------|-------|
| cornerRadius | 12pt | General corner radius |
| cardCornerRadius | 16pt | Cards, inputs, buttons |
| buttonCornerRadius | 10pt | Toggle buttons |
| spacing | 16pt | Standard spacing |
| smallSpacing | 8pt | Tight spacing |
| largeSpacing | 24pt | Section spacing |
| padding | 20pt | Screen padding |

### 6.4 Screen Specifications

#### 6.4.1 Login Screen
- App logo (gradient circle with dollar sign icon, 80x80pt)
- "Expense Tracker" title (28pt bold)
- "Sign in to manage your finances" subtitle (15pt)
- Email field: card background, envelope icon, email keyboard, no autocapitalization
- Password field: card background, lock icon, show/hide toggle eye icon
- Validation: email must contain "@"; password min 6 chars, alphanumeric (letters + digits)
- "Forgot Password?" link (14pt medium, right-aligned) — triggers Firebase reset email
- "Login" button: gradient fill (Primary to Secondary), 16pt vertical padding, disabled state gray
- Loading spinner inside button during login
- "Don't have an account? Sign Up" text link

#### 6.4.2 Register Screen
- "Create Account" title (28pt bold)
- "Sign up to start tracking your expenses" subtitle (15pt)
- Full Name field: person icon, words autocapitalization
- Birth Date field: calendar icon, compact DatePicker (max: today)
- Email field: envelope icon, email keyboard, no autocapitalization
- Phone Number field: phone icon, phone pad keyboard
- Password field: lock icon, show/hide toggle, "Min 6 characters" placeholder, alphanumeric required
- Confirm Password field: lock.rotation icon, show/hide toggle
- Password mismatch warning: red 12pt text below confirm field
- "Sign Up" button: gradient fill (Primary to Secondary), disabled state gray
- Loading spinner inside button during registration
- "Already have an account? Login" text link
- "Login" button in navigation toolbar (top-right)

#### 6.4.3 Dashboard Screen
- Total balance card with currency symbol
- Today's spending card (prominent, color-coded)
- Monthly income/expense summary
- Category spending summary (monthly breakdown by category)
- Recent transactions list (last 10)
- FAB button at bottom-right for adding transactions

#### 6.4.4 Transaction List Screen
- Filter tabs at top (All / Income / Expenses)
- Search bar
- Date-grouped transaction list
- Swipe actions: Edit (leading), Delete (trailing)
- Empty state with call-to-action when no transactions exist

#### 6.4.5 Add/Edit Transaction Sheet
- Income/Expense toggle (segmented control with red/green backgrounds)
- Amount input (large 48pt bold text with $ prefix)
- Quick amount buttons ($5, $10, $20, $50, $100)
- Category picker button (navigates to grid sheet)
- Date picker (compact, date + time)
- Payee text field (optional)
- Notes text field (optional)
- "Save Transaction" / "Update Transaction" button (gradient, disabled when invalid)
- Cancel button in navigation bar

#### 6.4.6 Settings Screen
- **Profile Section** (top):
  - Profile avatar circle with user initials
  - Full name, email (read-only), phone, birth date
  - Tap to open Edit Profile sheet
- **Currency Section**:
  - Currency picker menu
- **Theme Section**:
  - Light / Dark / System with icons
- **Preferences Section**:
  - Daily Expense Reminder toggle (with time picker)
- **Feedback Section**:
  - "Rate This App" button (star icon) — triggers App Store review
  - "Send Feedback" button (envelope icon) — opens Mail compose
- **Account Section** (bottom, destructive):
  - App version info
  - "Sign Out" button (red)
  - "Delete Account" button (red)
- **Navigation**: "Done" button (top-right) to dismiss sheet

#### 6.4.7 Forgot Password Screen/Flow
- User enters email address in a text field
- "Send Reset Email" button
- System calls Firebase Auth `sendPasswordReset` with the email
- On success: confirmation message "Password reset email sent. Check your inbox."
- On failure: error alert (e.g., "No account found with this email")
- "Back to Login" link

### 6.5 Design System

#### 6.5.1 Typography Scale

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| displayLarge | 36pt | bold | Balance amount on dashboard card |
| titleLarge | 28pt | bold | Screen titles (Login, Register) |
| titleMedium | 20pt | semibold | Section headers (Recent Transactions) |
| titleSmall | 16pt | semibold | Card titles, filter chips |
| bodyLarge | 15pt | regular | Subtitles, body text |
| bodyMedium | 14pt | regular | Field labels, secondary text |
| bodySmall | 13pt | regular | Version display, tertiary text |
| caption | 12pt | regular | Hints, warnings (password mismatch) |
| amountInput | 48pt | bold | Amount entry in transaction sheet |

All typography uses the system SF Pro font (default SwiftUI font). No custom fonts.

#### 6.5.2 Motion Spec

| Token | Duration | Curve | Usage |
|-------|----------|-------|-------|
| default | 0.25s | easeInOut | General transitions |
| sheetPresent | 0.35s | spring | Sheet presentations |
| fadeTransition | 0.2s | easeOut | Content appearance |
| buttonPress | 0.1s | easeIn | Button tap feedback |
| listDelete | 0.3s | easeOut | Transaction row deletion animation |

All animations respect `@Environment(\.accessibilityReduceMotion)`. When reduced motion is enabled, use instant crossfade (0.01s) instead of animations.

#### 6.5.3 Component Tokens

| Component | Background | Border | Corner Radius | Shadow |
|-----------|-----------|--------|---------------|--------|
| Card | Secondary Grouped BG | none | 16pt | none (rely on background contrast) |
| Input Field | Secondary Grouped BG | none | 16pt | none |
| Primary Button | Color.appPrimary | none | 16pt | none |
| Destructive Button | Color.appDanger | none | 16pt | none |
| Filter Chip (selected) | Color.appPrimary | none | 10pt | none |
| Filter Chip (unselected) | Secondary Grouped BG | none | 10pt | none |
| Category Grid Item | Secondary Grouped BG | none | 12pt | none |

#### 6.5.4 Spacing Grid

Base unit: 4pt. All spacing is a multiple of the base unit.

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4pt | Tight internal spacing |
| sm | 8pt | smallSpacing — between related items |
| md | 16pt | spacing — standard section gap |
| lg | 20pt | padding — screen edge padding |
| xl | 24pt | largeSpacing — major section gap |

### 6.6 Interaction States

#### 6.6.1 State Table

| Screen | Loading | Empty | Error | Success |
|--------|---------|-------|-------|---------|
| Login | Spinner in button, fields disabled | n/a | Alert with error message from Firebase | Transition to MainTabView |
| Register | Spinner in button, fields disabled | n/a | Alert with error message | Transition to MainTabView |
| Dashboard | ProgressView overlay while fetching Firestore data | Welcome card: "Add your first transaction" with CTA button, balance shows "$0.00" | Banner: "Unable to load data. Pull to retry." | Real-time updates via Firestore listener |
| Transaction List | ProgressView while fetching | Illustration + "No transactions yet. Tap + to add one." + CTA button | Banner: "Something went wrong. Pull to retry." | List updates in real-time |
| Transaction List (filter/search empty) | n/a | "No results found" with clear filter button | n/a | n/a |
| Add Transaction | Spinner in save button during Firestore write | n/a | Alert: "Failed to save. Will retry when online." | Haptic feedback (UIImpactFeedbackGenerator .light), sheet dismisses |
| Edit Transaction | Spinner in save button | n/a | Alert: "Failed to update. Will retry when online." | Haptic feedback, sheet dismisses |
| Delete Transaction | n/a | n/a | n/a | Undo toast for 3 seconds: "Transaction deleted. UNDO" |
| Settings | n/a | n/a | n/a | n/a |
| Forgot Password | Spinner in button | n/a | Alert: "No account found with this email." | Confirmation: "Reset email sent. Check your inbox." |

#### 6.6.2 First Launch Experience

When a user registers and opens the Dashboard for the first time:
1. Balance card shows "$0.00" with label "Total Balance"
2. Monthly income/expense show "$0.00"
3. Recent Transactions section shows a **welcome card**:
   - Icon: sparkles (SF Symbol)
   - Title: "Welcome to Expense Tracker!"
   - Body: "Tap the + button to record your first transaction."
   - CTA: "Add Transaction" button (appPrimary color)
4. Category spending section is hidden (no spending yet)
5. After the first transaction is added, the welcome card is permanently replaced with the standard recent transactions list

### 6.7 Accessibility Requirements

#### 6.7.1 VoiceOver

- All interactive elements shall have meaningful `accessibilityLabel` values
- Transaction rows: "Groceries expense, $45.50, today at 2:30 PM" (category + type + amount + date)
- FAB: "Add new transaction"
- Category grid items: category name (color is not the only identifier)
- Filter chips: include selected state ("All, selected" / "Income, not selected")
- Toggle buttons: announce state ("Income selected" / "Expense selected")
- Quick amount buttons: "Add $5 to amount"
- Balance card: "Total balance, $1,234.56"
- Buttons with spinners: "Logging in, please wait"

#### 6.7.2 Dynamic Type

- Support Dynamic Type sizes from xSmall to xxxLarge
- Balance amount on dashboard: scales with Dynamic Type but clamped to max 48pt
- Transaction list rows: must remain readable at xxxLarge (may need to wrap to 2 lines)
- Quick amount buttons: fixed size (do not scale with Dynamic Type)

#### 6.7.3 Color and Contrast

- All text must meet WCAG AA contrast ratio (4.5:1 for body text, 3:1 for large text)
- Balance card: white text on gradient background must pass contrast check at both gradient endpoints
- Income/expense amounts: color is supplemented with "+" / "-" prefix for colorblind users
- Category colors: supplemented by unique SF Symbol icons (not color-only identification)
- Error states: use `.appDanger` red supplemented with SF Symbol (exclamationmark.triangle) and text

#### 6.7.4 Touch Targets

- Minimum touch target: 44x44pt (Apple HIG)
- Quick amount buttons: minimum 44x36pt tap area
- Filter chips: minimum 44x36pt tap area
- Swipe actions: full row height swipe area
- FAB: 56x56pt (exceeds minimum)

#### 6.7.5 Reduced Motion

- All animations respect `@Environment(\.accessibilityReduceMotion)`
- When enabled: use instant crossfade (0.01s) instead of spring/ease animations
- Sheet presentations: use fade instead of slide
- Transaction deletion: instant remove instead of slide-out animation

### 6.8 User Journey

| Step | User Does | User Feels | Screen | What Supports It |
|------|-----------|------------|--------|------------------|
| 1 | Opens app | Curious | Login | Clean design, clear "Sign Up" link |
| 2 | Taps "Sign Up" | Committed | Register | Clear form, field-level validation |
| 3 | Submits registration | Expectation | Loading spinner | Spinner in button, fields disabled |
| 4 | Registration succeeds | Accomplished | Dashboard (empty) | Welcome card with CTA |
| 5 | Taps "+" or CTA | Productive | Add Transaction | Large amount input, quick amounts |
| 6 | Saves transaction | Satisfied | Dashboard | Haptic feedback, balance updates |
| 7 | Views transactions | In control | Transaction List | Date grouping, search, filter |
| 8 | Edits a transaction | Correcting | Edit Sheet | Pre-populated form |
| 9 | Deletes a transaction | Uncertain | Undo toast | "Deleted. UNDO" for 3 seconds |
| 10 | Returns next day | Trusting | Dashboard | Data persisted, auto-login |
| 11 | Network fails offline | Anxious | Any screen | Firestore caches, no data loss |

### 6.9 Resolved Design Decisions

| Decision | Resolution | Rationale |
|----------|-----------|-----------|
| Calendar view scope | Future scope only | Revision history corrected. Not in current version. |
| iOS target | 18.5 | Matches actual Xcode deployment target. Enables iOS 18 APIs. |
| Birth date on register | Kept (required) | Used for user profile display and potential age-based features. |
| Phone on register | Kept (required) | Stored in profile for potential future SMS verification. |
| Logout placement | Settings screen, destructive red button | Standard iOS pattern for account actions. |
| Session persistence | Firebase Auth auto-handles | `addStateDidChangeListener` drives auth state. |
| Quick amounts | USD-denominated for now | Currency-aware amounts deferred to future scope. |
| Forgot Password | Fully specified (FR-1.4, 6.4.7) | Firebase reset email flow with confirmation. |
| Success feedback | Haptic on save, undo toast on delete | iOS convention. Trust-building. |
| Data persistence story | Firestore as target, in-memory as current | Clear Phase 1/Phase 2 distinction in implementation status. |
| Dashboard empty state | Welcome card with CTA | Guides new users to first action. |
| Gradient vs solid buttons | Gradient (Primary→Secondary) retained | Consistent with existing implementation and brand. |
| Swipe edit placement | Leading edge for Edit, trailing for Delete | Standard iOS pattern: positive leading, destructive trailing. |
| Firestore document ID | Firebase Auth UID (not email) | UID is immutable; email can change. Simpler security rules. |
| Currency/theme source of truth | Firestore, @AppStorage as cache | Consistent across devices. Firestore loaded on login, cached locally. |
| DataService replacement | FirestoreDataService replaces DataService in production | Same protocol, different implementation. DataService kept for testing. |
| Delete account strategy | Batch delete subcollections (500/batch) + spinner | Firestore doesn't cascade deletes. Must delete each transaction. |
| Protocol design | Async from the start | Both protocols use async/await. In-memory DataService wraps in Task. |
| Transaction pagination | Dashboard: 10 recent, List: 50 per page infinite scroll | Avoids loading all transactions. Meets 2s dashboard NFR. |
| Category aggregation | Client-side from monthly data | Query month's transactions, aggregate in Swift. No server-side aggregation needed. |

---

## 7. System Architecture

### 7.1 Architectural Pattern: MVVM

```
+----------------------------------------------------------+
|                         Views                             |
|  (SwiftUI — observes @StateObject ViewModels)            |
|  LoginView | RegisterView | Dashboard | Transactions     |
|  Settings | EditProfile | ForgotPassword                 |
+-----------------+-------------------------+--------------+
                  |                         |
                  v                         v
+---------------------------+  +---------------------------+
|  AuthViewModel            |  |  DashboardViewModel       |
|  (Firebase Auth state)    |  |  TransactionViewModel     |
|                           |  |  SettingsViewModel        |
|  @MainActor               |  |  @MainActor               |
|  @Published properties    |  |  @Published properties    |
+-------------+-------------+  +-------------+-------------+
              |                              |
              v                              v
+---------------------------+  +---------------------------+
| FirebaseAuthService       |  |  FirestoreDataService     |
| (implements               |  |  (implements              |
|   AuthServiceProtocol)    |  |    DataServiceProtocol)   |
|                           |  |                           |
| - Firebase Auth SDK       |  |  - Firebase Firestore SDK |
| - Login / Register /      |  |  - CRUD operations        |
|   Logout / Delete Account |  |  - Computed totals        |
| - Password Reset          |  |  - Date grouping          |
| - Auth state listener     |  |  - Real-time sync         |
+---------------------------+  +---------------------------+
              |                              |
              v                              v
+---------------------------+  +---------------------------+
|  Firebase Auth            |  |  Firebase Firestore       |
|  (Email/Password)         |  |  users/{uid}              |
|                           |  |  users/{uid}/transactions |
+---------------------------+  +---------------------------+
                                            |
                                            v
                              +---------------------------+
                              |       Models              |
                              |  Transaction              |
                              |  Category (hardcoded)     |
                              |  UserProfile              |
                              +---------------------------+
```

### 7.2 Component Responsibilities

| Component | File(s) | Responsibility | Status |
|-----------|---------|---------------|--------|
| **Views** | `Views/**/*.swift` | Render UI, capture user input, observe ViewModel state | Done |
| **ViewModels** | `ViewModels/*.swift` | Transform data for display, handle user actions, coordinate with services | Partial (no AuthViewModel) |
| **AuthServiceProtocol** | `Protocols/AuthServiceProtocol.swift` | Protocol for auth operations (register, login, logout, state listener) | Protocol defined |
| **DataServiceProtocol** | `Protocols/DataServiceProtocol.swift` | Protocol for data CRUD, totals, grouping | Protocol defined |
| **FirebaseAuthService** | `Services/FirebaseAuthService.swift` | Firebase Auth implementation of AuthServiceProtocol | Not started |
| **FirestoreDataService** | `Services/FirestoreDataService.swift` | Firestore implementation of DataServiceProtocol; replaces DataService in production | Not started |
| **DataService** | `Services/DataService.swift` | In-memory store implementing DataServiceProtocol; used for development/testing only, not in production | Done |
| **Models** | `Models/*.swift` | Data structures (Transaction, Category, UserProfile) | Done |
| **Extensions** | `Utils/Extensions/*.swift` | Formatting (currency, date, color), theme colors | Done |
| **Constants** | `Utils/Constants.swift` | Layout values, notification names | Done |
| **MockAuthService** | `Tests/Mocks/MockAuthService.swift` | Mock auth service for unit testing | Done |
| **MockDataService** | `Tests/Mocks/MockDataService.swift` | Mock data service for unit testing | Done |
| **ProtocolSmokeTests** | `Tests/ProtocolSmokeTests.swift` | Protocol conformance smoke tests | Done |

### 7.3 Data Flow

1. **App entry** (`ExpenseTrackerAppApp`): checks Firebase Auth state — if authenticated user exists, shows MainTabView; otherwise shows AuthGateView
2. **Auth gate** (`AuthGateView`): manages NavigationStack for Login <-> Register
3. **AuthViewModel**: observes Firebase Auth state listener; publishes `AuthState` (.loading, .authenticated, .unauthenticated)
4. **ViewModels**: receive data service via dependency injection; own `@Published` display state
5. **Views**: observe `@StateObject` ViewModels
6. **FirestoreDataService**: syncs transactions with Firestore in real-time; caches locally for offline use
7. **Notification-based updates**: DataService posts `NotificationCenter` events after CRUD; ViewModels subscribe and recalculate

### 7.4 Notification-Based Updates

| Notification | Trigger |
|---|---|
| `transactionAdded` | New transaction created |
| `transactionUpdated` | Transaction edited |
| `transactionDeleted` | Transaction removed |

### 7.5 Protocol Specifications

#### 7.5.1 AuthServiceProtocol

```swift
protocol AuthServiceProtocol: AnyObject {
    var authState: AuthState { get }
    func register(email: String, password: String, name: String,
                  birthDate: Date, phone: String) async throws -> UserProfile
    func login(email: String, password: String) async throws -> UserProfile
    func logout() async throws
    func deleteAccount() async throws
    func resetPassword(email: String) async throws
    func addAuthStateListener(_ listener: @escaping (AuthState) -> Void)
    func removeAuthStateListener()
}

enum AuthState {
    case loading
    case authenticated(UserProfile)
    case unauthenticated
}
```

#### 7.5.2 DataServiceProtocol

```swift
protocol DataServiceProtocol: AnyObject, ObservableObject {
    var transactions: [Transaction] { get set }
    var categories: [Category] { get set }
    var userProfile: UserProfile? { get set }

    // Computed totals
    var totalBalance: Double { get }
    var totalExpensesThisMonth: Double { get }
    var totalIncomeThisMonth: Double { get }

    // CRUD (all async for Firestore compatibility)
    func loadData() async throws
    func addTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(_ transaction: Transaction) async throws

    // Helpers
    func category(for id: UUID) -> Category?
    func groupedTransactions() -> [(String, [Transaction])]
}
```

### 7.6 Error Handling Architecture

#### 7.6.1 AppError Type

```swift
enum AppError: LocalizedError {
    case auth(AuthError)
    case network(NetworkError)
    case data(DataError)
    case validation(ValidationError)

    var errorDescription: String? { /* maps to user-friendly message */ }
}

enum AuthError {
    case invalidCredentials
    case emailInUse
    case weakPassword
    case passwordMismatch
    case userNotFound
    case sessionExpired
}

enum NetworkError {
    case noConnection
    case timeout
    case serverError(String)
}

enum DataError {
    case saveFailed
    case loadFailed
    case deleteFailed
}

enum ValidationError {
    case emptyField(String)
    case invalidEmail
    case invalidPassword
    case futureDate
    case invalidPhone
}
```

#### 7.6.2 Error Flow

1. **Service layer** throws `AppError` (maps Firebase errors to app errors)
2. **ViewModel** catches via `do/catch`, sets `@Published var error: AppError?`
3. **View** observes error via `.alert(item: $viewModel.error)` and displays user-friendly message
4. All ViewModels include: `@Published var error: AppError?` and `@Published var isLoading: Bool`

### 7.7 Data Sync Strategy

Currency and theme preferences use Firestore as the **source of truth**:

1. **On login**: load user profile from Firestore, write currency/theme to `@AppStorage` as local cache
2. **On settings change**: write to Firestore first, then update `@AppStorage` on success
3. **On app launch (auto-login)**: read from Firestore, update `@AppStorage` cache
4. **Conflict resolution**: Firestore value always wins over local `@AppStorage`

This ensures consistency across devices and sessions while keeping `@AppStorage` as a fast local cache for UI rendering.

### 7.8 Firestore Composite Indexes

Required composite indexes for paginated and filtered queries:

```json
{
  "indexes": [
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "date", "order": "DESCENDING" },
        { "fieldPath": "amount", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "transactions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "categoryId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    }
  ],
  "fieldOverrides": []
}
```

Defined in `Firestore/firestore.indexes.json` in the Firebase project directory.

---

## 8. Project Structure

```
ExpenseTrackerApp/
+-- ExpenseTrackerAppApp.swift           # @main entry — auth gate, injects DataService
+-- Models/
|   +-- Transaction.swift                # Amount: +income, -expense; date grouping helpers
|   +-- Category.swift                   # 12 built-in categories with icons/colors
|   +-- UserProfile.swift                # Theme, currency, profile preferences
+-- Protocols/
|   +-- AuthServiceProtocol.swift        # Auth operations protocol + AuthState enum
|   +-- DataServiceProtocol.swift        # Data CRUD protocol
+-- ViewModels/
|   +-- DashboardViewModel.swift         # Balance, income, expenses, recent transactions
|   +-- TransactionViewModel.swift       # Filtering, sorting, search, CRUD delegation
|   +-- SettingsViewModel.swift          # Currency, theme, profile, reminder settings
+-- Views/
|   +-- MainTabView.swift                # 2-tab bar + Settings button + FAB
|   +-- Auth/
|   |   +-- LoginView.swift              # Email/password login with forgot password link
|   |   +-- RegisterView.swift           # Full registration form (6 fields)
|   |   +-- ForgotPasswordView.swift     # Firebase password reset email
|   +-- Dashboard/
|   |   +-- DashboardView.swift          # Balance, today's spending, category summary
|   +-- Transactions/
|   |   +-- TransactionsView.swift       # Date-grouped list with search & filter
|   |   +-- AddTransactionView.swift     # Add/edit transaction sheet
|   +-- Settings/
|   |   +-- SettingsView.swift           # Profile, currency, theme, reminder, sign out
|   |   +-- EditProfileView.swift        # Edit profile sheet
|   |   +-- CurrencyPickerView.swift     # Currency selection
|   |   +-- ThemeSelectionView.swift     # Theme selection
|   +-- Components/
|       +-- CategoryPickerGrid.swift     # Category selection grid
|       +-- QuickActionButton.swift      # FAB, quick action buttons, quick amounts
|       +-- TransactionRow.swift         # Transaction list item
+-- Services/
|   +-- DataService.swift                # In-memory data store (current)
|   +-- FirebaseAuthService.swift        # Firebase Auth implementation (planned)
|   +-- FirestoreDataService.swift       # Firestore implementation (planned)
+-- Utils/
|   +-- Constants.swift                  # Layout values, Notification.Name extensions
|   +-- Extensions/
|       +-- Color+Theme.swift            # App colors, hex init
|       +-- Date+Extensions.swift        # startOfMonth, isThisMonth, dateGroupTitle
|       +-- Double+Currency.swift        # Currency formatting helpers
ExpenseTrackerAppTests/
+-- ExpenseTrackerAppTests.swift         # Basic unit tests
+-- ProtocolSmokeTests.swift             # Protocol conformance smoke tests
+-- Mocks/
    +-- MockAuthService.swift            # Mock auth service for testing
    +-- MockDataService.swift            # Mock data service for testing
ExpenseTrackerAppUITests/
+-- ExpenseTrackerAppUITests.swift       # UI tests
+-- ExpenseTrackerAppUITestsLaunchTests.swift  # Launch tests
```

---

## 9. Assumptions and Dependencies

### 9.1 Assumptions

1. The user has an iOS device running iOS 18.5 or later
2. All transactions are manually entered (no automatic bank feed)
3. A single currency applies to all transactions
4. One balance tracks all transactions (no multi-account)
5. Internet connection available for initial authentication; offline supported via Firestore cache

### 9.2 Dependencies

| Dependency | Version | Purpose |
|------------|---------|---------|
| SwiftUI | iOS 18.5+ | UI framework |
| Foundation | — | Core Swift libraries |
| Combine | — | Reactive programming (@Published, NotificationCenter subscriptions) |
| XCTest | — | Unit testing framework |
| Firebase Auth | Latest (SPM) | User authentication (Email/Password) |
| Firebase Firestore | Latest (SPM) | Cloud database for transactions and user data |
| UserNotifications | — | Local notification scheduling (daily reminder) |
| MessageUI | — | In-app mail compose (feedback) |
| StoreKit | — | App Store review prompt (SKStoreReviewController) |

---

## 10. Implementation Status

### 10.1 Feature Status Matrix

| Feature | Status | Notes |
|---------|--------|-------|
| Dashboard (balance, monthly stats) | Done | In-memory with sample data |
| Transaction CRUD | Done | Add, edit, delete, search, filter |
| Category system (12 built-in) | Done | Grid picker, system flags |
| Settings (currency, theme) | Done | Persisted via @AppStorage |
| Login Screen UI | Done | Static — Firebase Auth not yet connected |
| Register Screen UI | Done | Static — Firebase Auth not yet connected |
| Auth gate navigation | Done | Login/Register to Main app |
| DataServiceProtocol | Done | Protocol extracted |
| AuthServiceProtocol | Done | Protocol defined (needs birthDate param update) |
| ProtocolSmokeTests | Done | 11 test methods covering both mocks |
| MockAuthService | Done | Mock for testing |
| MockDataService | Done | Mock for testing |
| Firebase Auth integration | Not started | Planned — FirebaseAuthService |
| Firestore data persistence | Not started | Planned — FirestoreDataService |
| Firestore security rules | Not started | Planned |
| AuthViewModel | Not started | Planned |
| Sign Out | Not started | Planned — in Settings screen |
| Delete Account | Not started | Planned — in Settings screen |
| Auto-Login | Not started | Planned — Firebase session persistence |
| Forgot Password (Firebase) | Not started | Planned — Firebase reset email |
| Password reset email flow | Not started | Planned |
| Today's Spending card | Not started | Planned — on Dashboard |
| Category Spending Summary | Not started | Planned — on Dashboard |
| Receipt Photo attachment | Deferred | Moved to future scope — requires Firebase Storage |
| Daily Expense Reminder | Not started | Planned — local notifications |
| View/Edit Profile | Not started | Planned — in Settings |
| Edit Profile sheet | Not started | Planned |
| Rate & Review App | Not started | Planned — SKStoreReviewController |
| Contact Support / Feedback | Not started | Planned — MessageUI |
| Auth error handling | Not started | Planned — Firebase error mapping |
| Transaction pagination | Not started | Planned — Dashboard: limit 10, List: 50 per page infinite scroll |
| AppError type | Not started | Planned — unified error enum for auth, network, data, validation |
| Async protocol migration | Not started | Planned — DataServiceProtocol and AuthServiceProtocol async/await |
| Firestore composite indexes | Not started | Planned — indexes for date, categoryId, pagination queries |
| Currency/theme Firestore sync | Not started | Planned — Firestore as source of truth, @AppStorage as cache |

---

## 11. Future Scope

The following features are identified for future development but are **out of scope** for the current version:

| Priority | Feature | Description |
|----------|---------|-------------|
| High | Receipt photo attachment | Attach receipt photos to transactions via camera/photo library, stored in Firebase Storage |
| Medium | Multiple accounts | Separate balances for different accounts |
| Medium | Budget tracking | Set monthly spending limits per category |
| Medium | Charts and analytics | Visual spending trends |
| Low | Recurring transactions | Auto-add scheduled bills |
| Low | Social login | Google, Apple Sign-In authentication |
| Low | Widget support | Quick transaction entry from home screen |
| Low | Data export | CSV/PDF export of transactions |
| Low | iPad support | Adaptive layout for tablet form factors |

---

## 12. Test Requirements

### 12.1 Coverage Target

80% code coverage on ViewModels and Services. Measured via Xcode coverage reports.

### 12.2 Required Test Suites

| Suite | File | Tests | SRS Coverage |
|-------|------|-------|-------------|
| **DashboardViewModelTests** | `Tests/DashboardViewModelTests.swift` | Balance calculations, monthly totals, recent transactions, category lookup, refresh | FR-2.1, FR-2.2, FR-2.3, FR-2.4, FR-2.6 |
| **TransactionViewModelTests** | `Tests/TransactionViewModelTests.swift` | Filter pipeline (all/income/expense), search (payee/notes), sort (date asc/desc), CRUD delegation, date grouping | FR-3.1, FR-3.2, FR-3.5, FR-3.6 |
| **SettingsViewModelTests** | `Tests/SettingsViewModelTests.swift` | Currency selection, theme toggle, @AppStorage persistence, Firestore sync | FR-5.1, FR-5.2 |
| **AuthViewModelTests** | `Tests/AuthViewModelTests.swift` | Login success/failure, register success/failure, logout, delete account, password reset, auth state transitions | FR-1.1, FR-1.2, FR-1.5, FR-1.6, FR-1.7 |
| **DataServiceProtocolTests** | `Tests/ProtocolSmokeTests.swift` | MockDataService CRUD, totals, grouping, category lookup | NFR-5.4 |
| **AuthServiceProtocolTests** | `Tests/ProtocolSmokeTests.swift` | MockAuthService register/login/logout, state listener, failure injection | NFR-5.4 |
| **FirestoreDataServiceTests** | `Tests/FirestoreDataServiceTests.swift` | CRUD with Firestore emulator, pagination (limit/cursor), offline cache, error mapping | FR-3.7, FR-3.8, NFR-3.3 |
| **FirebaseAuthServiceTests** | `Tests/FirebaseAuthServiceTests.swift` | Auth with Firebase emulator, error mapping, session persistence | FR-1.4, FR-1.7 |
| **ModelTests** | `Tests/ModelTests.swift` | Transaction computed properties, date grouping, currency formatting, validation rules | FR-3, DR-1 through DR-11 |
| **AppErrorTests** | `Tests/AppErrorTests.swift` | Error mapping, user-friendly messages, all error cases | Section 7.6 |

### 12.3 Edge Cases

| Test | Description |
|------|-------------|
| Empty transactions | Balance = $0.00, empty recent list, welcome card shown |
| Large dataset | 1000 transactions, filter/sort < 200ms, scroll 60fps |
| Currency formatting | All supported currencies, zero amount, negative amount |
| Date boundaries | Today, yesterday, this week, this month, older grouping |
| Offline mode | CRUD queued, reads from cache, sync on reconnect |
| Concurrent edits | Two devices, Firestore merge conflict resolution |
| Invalid inputs | Empty fields, future dates, special characters in payee |
| Auth state transitions | Loading → authenticated, Loading → unauthenticated, authenticated → unauthenticated (logout) |
| Delete account with data | Batch delete 500+ transactions, progress tracking |

### 12.4 Testing Infrastructure

- **Firebase Emulator Suite** for Firestore and Auth tests (no real backend needed)
- **MockDataService** / **MockAuthService** for ViewModel unit tests (async/await versions)
- **XCTest** framework with `@MainActor` test classes for ViewModel tests
- **Performance tests**: `measure {}` blocks for filter/sort operations

---

## Appendix A: Error Handling

### Transaction Errors

| Scenario | Message | Recovery |
|----------|---------|----------|
| Empty amount on save | "Please enter an amount" | Enter amount |
| No category selected | "Please select a category" | Select a category |
| Delete confirmation | "Delete this transaction?" | Confirm or cancel |

### Authentication Errors

| Scenario | Message | Recovery |
|----------|---------|----------|
| Invalid email/password | "Invalid email or password. Please try again." | Re-enter credentials |
| Email already in use | "An account with this email already exists." | Log in instead |
| Weak password | "Password is too weak. Use at least 6 characters with letters and numbers." | Enter stronger password |
| Network error | "Unable to connect. Please check your internet connection." | Retry when online |
| Password mismatch (Register) | "Passwords do not match" | Re-enter confirm password |
| Invalid email format | Form button stays disabled | Enter valid email with "@" |
| Forgot Password - email not found | "No account found with this email address." | Verify email or register |

### Account Errors

| Scenario | Message | Recovery |
|----------|---------|----------|
| Sign Out confirmation | "Are you sure you want to sign out?" | Confirm or cancel |
| Delete Account confirmation | "Type DELETE to confirm account deletion" | Type DELETE or cancel |
| Delete Account warning | "This action is permanent and cannot be undone." | User must type DELETE |

### Firestore Errors

| Scenario | Message | Recovery |
|----------|---------|----------|
| Firestore write failure | "Failed to save. Changes will sync when you're back online." | Automatic retry via Firestore SDK |
| Firestore read failure | Shows last cached data | Automatic retry via Firestore SDK |

---

## Appendix B: Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-04 | Arpit Parekh | Initial SRS — full-featured expense tracker |
| 2.0 | 2026-04-04 | Arpit Parekh | Simplified scope to transaction recording only |
| 3.0 | 2026-04-12 | Arpit Parekh | Added Login/Register screens (static UI), protocols, updated to reflect actual implementation state |
| 4.0 | 2026-04-18 | Arpit Parekh | Major update: Firebase Auth + Firestore backend, sign out, delete account, auto-login, forgot password, today's spending, category summary, receipt photos, daily reminder, view/edit profile, rate app, feedback, Firestore schema/security rules, corrected iOS target to 18.5, corrected tab structure to 2 tabs + settings button |
| 4.1 | 2026-04-18 | Arpit Parekh | Design review (plan-design-review): added design system (typography scale, motion spec, component tokens, spacing grid), interaction states table, first-launch experience, accessibility requirements (VoiceOver, Dynamic Type, contrast, touch targets, reduced motion), user journey storyboard, resolved design decisions |
| 4.2 | 2026-04-18 | Arpit Parekh | Engineering review (plan-eng-review): Firestore document ID changed from email to UID, receipt photos deferred to future scope, Firestore as source of truth for currency/theme, FirestoreDataService replaces DataService, batch delete for account deletion, added protocol specifications (AuthServiceProtocol, DataServiceProtocol async), added AppError type and error flow, added data sync strategy, added transaction pagination (10 dashboard / 50 list), client-side category aggregation, added Firestore composite indexes, added test plan with 10 test suites and edge cases, fixed duplicate Forgot Password section, fixed MockAuthService gender→birthDate |

---

*End of Software Requirements Specification*

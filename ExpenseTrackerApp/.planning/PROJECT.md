# ExpenseTrackerApp — Firebase Auth & Firestore Migration

## What This Is

A simple SwiftUI iOS expense tracker that currently records daily transactions (income/expenses) in-memory. This project adds Firebase Authentication (login/register/logout), migrates data storage to Firebase Firestore (per-user persistence), and establishes unit testing infrastructure. The app uses MVVM architecture with protocol-based services for testability.

## Core Value

Users can securely log in, have their transactions persisted across sessions, and trust the app works correctly through automated tests.

## Requirements

### Validated

<!-- Existing capabilities from v2.0 codebase -->

- ✓ Transaction CRUD (add, edit, delete) with amount, category, date, payee, notes — existing
- ✓ Dashboard with total balance, monthly income/expenses, recent transactions — existing
- ✓ Transaction list with date grouping, search, filter (All/Income/Expense), sort — existing
- ✓ 12 built-in categories with icons and colors — existing
- ✓ Settings with currency selection and theme (Light/Dark/System) — existing
- ✓ MVVM architecture with in-memory DataService — existing
- ✓ Protocol-based service abstraction (DataServiceProtocol, AuthServiceProtocol) for dependency injection — Validated in Phase 1: Protocol Extraction

### Active

<!-- New scope for this milestone -->

- [ ] User can register with Name, Gender, Phone Number, Email, and Password
- [ ] User can log in with Email and Password
- [ ] User can log out from the app
- [ ] User session persists across app launches
- [ ] User's transactions are stored in Firebase Firestore, scoped per user UID
- [ ] Unauthenticated users see login/register screen, not the main app
- [ ] Unit tests for all ViewModels (Dashboard, Transaction, Settings, Auth)
- [ ] Unit tests for DataService and AuthService
- [ ] 80% code coverage on ViewModels and Services

### Out of Scope

<!-- Explicit boundaries -->

- Email verification — not needed for v1, can add later
- Password reset — deferred to future milestone
- Biometric authentication (Face ID/Touch ID) — deferred
- OAuth/social login (Google, Apple) — deferred
- Data export — not requested
- Budget management — removed in v2.0, not returning
- Multi-account management — removed in v2.0, not returning
- Goal tracking — removed in v2.0, not returning
- Recurring transactions — removed in v2.0, not returning

## Context

### Existing Codebase (Brownfield)

- Swift/SwiftUI iOS app targeting iOS 18.5+
- MVVM architecture with 3 ViewModels, 1 DataService (singleton, in-memory)
- ~20 source files: 3 models, 3 ViewModels, 9 views, 3 components, 1 service, 4 utils
- Zero external dependencies — Firebase will be the first via SPM
- Zero test coverage — XCTest target exists but empty
- DataService is a concrete singleton — needs protocol extraction for testability
- ViewModels use default `DataService.shared` — need protocol-based DI
- Notification-based updates for cross-ViewModel communication

### Technical Decisions Already Made

- Firebase Auth with Email/Password provider
- Firebase Firestore for data persistence
- Firestore collections scoped by user: `users/{uid}/transactions`, `users/{uid}/profile`
- Registration fields: Name, Gender, Phone Number (stored in Firestore profile document)
- Unit tests written first (protocol extraction enables mocking)

## Constraints

- **Tech Stack**: Swift 5.0, SwiftUI, iOS 18.5+, Firebase SDK via SPM
- **Architecture**: MVVM with protocol-based services for DI and testability
- **Testing**: XCTest with protocol mocks, 80% coverage target on ViewModels/Services
- **No external UI libraries**: All SwiftUI native
- **Single currency per user**: No multi-currency support
- **Single balance**: All transactions tracked against one total per user

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Firebase Auth (Email/Password) | Managed auth service, handles session persistence, scales well for indie app | — Pending |
| Firebase Firestore | Real-time sync, per-user scoping, integrates with Firebase Auth | — Pending |
| Protocol-based services before Firebase | Enables unit testing with mocks; Firebase implementation becomes a conformance | — Pending |
| Unit tests written alongside code | Protocol extraction first, then tests, then Firebase implementation | — Pending |
| Registration collects Name, Gender, Phone | User requirement — stored in Firestore profile document alongside email | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-04-05 after initialization*

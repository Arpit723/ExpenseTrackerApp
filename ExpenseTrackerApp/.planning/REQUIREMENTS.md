# Requirements: ExpenseTrackerApp — Firebase Auth & Firestore Migration

**Defined:** 2026-04-05
**Core Value:** Users can securely log in, have their transactions persisted across sessions, and trust the app works correctly through automated tests.

## v1 Requirements

### Architecture

- [ ] **ARCH-01**: DataServiceProtocol extracted from existing DataService with all CRUD operations and computed properties
- [ ] **ARCH-02**: AuthServiceProtocol defined with register, login, logout, and auth state listener methods
- [ ] **ARCH-03**: All ViewModels accept service protocols via init (not concrete types) for dependency injection
- [ ] **ARCH-04**: MockDataService and MockAuthService conform to protocols for unit testing
- [ ] **ARCH-05**: FirebaseAuthService conforms to AuthServiceProtocol
- [ ] **ARCH-06**: FirestoreDataService conforms to DataServiceProtocol with per-user data scoping

### Authentication

- [ ] **AUTH-01**: User can register with Name, Gender, Phone Number, Email, and Password via custom SwiftUI form
- [ ] **AUTH-02**: User can log in with Email and Password
- [ ] **AUTH-03**: User can log out from the app, which clears all local state
- [ ] **AUTH-04**: User session persists across app launches via Firebase automatic keychain storage
- [ ] **AUTH-05**: App uses three-state auth model (loading/authenticated/unauthenticated) to prevent login screen flash
- [ ] **AUTH-06**: Root view conditionally shows auth screens or main app based on authentication state
- [ ] **AUTH-07**: Registration writes profile document (Name, Gender, Phone) to Firestore `users/{uid}/profile`
- [ ] **AUTH-08**: Auth errors are mapped to typed AuthError enum with user-facing messages

### Data Persistence

- [ ] **DATA-01**: Transactions stored in Firestore subcollection `users/{uid}/transactions` scoped per authenticated user
- [ ] **DATA-02**: User profile stored in Firestore document `users/{uid}/profile` with Name, Gender, Phone, Email
- [ ] **DATA-03**: Existing DataService CRUD operations (add, update, delete transaction) work through Firestore
- [ ] **DATA-04**: Dashboard computed properties (balance, income, expenses) work with Firestore-backed data
- [ ] **DATA-05**: Firestore security rules enforce per-user data isolation (`request.auth.uid == resource.data.userId`)

### Unit Testing

- [ ] **TEST-01**: Unit tests for AuthViewModel — registration validation, login flow, logout flow, error mapping, state transitions
- [ ] **TEST-02**: Unit tests for DashboardViewModel — balance calculations, recent transactions, category lookup (mock DataService)
- [ ] **TEST-03**: Unit tests for TransactionViewModel — filtering, sorting, search, CRUD delegation (mock DataService)
- [ ] **TEST-04**: Unit tests for SettingsViewModel — currency and theme changes (mock DataService)
- [ ] **TEST-05**: Unit tests for DataService — protocol conformance, computed properties (mock implementation)
- [ ] **TEST-06**: Unit tests for AuthService — protocol conformance, auth state transitions (mock implementation)
- [ ] **TEST-07**: 80% code coverage on ViewModels and Services

### UX Polish

- [ ] **UX-01**: Loading spinner and disabled buttons during auth operations (login, register, logout)
- [ ] **UX-02**: Inline form validation for registration fields (email format, password strength, required fields)
- [ ] **UX-03**: User-facing error alerts with specific messages for common auth failures

## v2 Requirements

### Authentication Enhancements

- **AUTH-09**: User can reset password via email link
- **AUTH-10**: User receives email verification after registration
- **AUTH-11**: User can log in with Google OAuth
- **AUTH-12**: User can log in with Apple Sign In
- **AUTH-13**: User can authenticate with Face ID / Touch ID

### Data Enhancements

- **DATA-06**: Real-time transaction sync across devices via Firestore snapshot listeners
- **DATA-07**: Explicit offline-first design with conflict resolution
- **DATA-08**: Data export (CSV/PDF)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Budget management | Removed in v2.0, not returning |
| Multi-account management | Removed in v2.0, not returning |
| Goal tracking | Removed in v2.0, not returning |
| Recurring transactions | Removed in v2.0, not returning |
| Biometric auth | Deferred to v2 — requires LocalAuthentication framework |
| OAuth/social login | Deferred to v2 — protocol extraction enables easy addition later |
| Email verification | Deferred to v2 — not needed for personal expense tracker v1 |
| Password reset | Deferred to v2 — trivial to add via AuthServiceProtocol |
| Real-time Firestore listeners | Overkill for single-user, single-device app — use one-time fetches |
| FirebaseUI | Conflicts with custom SwiftUI design and custom registration fields |
| Data export | Not requested |
| Multi-currency | Single currency per user, not changing |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | — | Pending |
| ARCH-02 | — | Pending |
| ARCH-03 | — | Pending |
| ARCH-04 | — | Pending |
| ARCH-05 | — | Pending |
| ARCH-06 | — | Pending |
| AUTH-01 | — | Pending |
| AUTH-02 | — | Pending |
| AUTH-03 | — | Pending |
| AUTH-04 | — | Pending |
| AUTH-05 | — | Pending |
| AUTH-06 | — | Pending |
| AUTH-07 | — | Pending |
| AUTH-08 | — | Pending |
| DATA-01 | — | Pending |
| DATA-02 | — | Pending |
| DATA-03 | — | Pending |
| DATA-04 | — | Pending |
| DATA-05 | — | Pending |
| TEST-01 | — | Pending |
| TEST-02 | — | Pending |
| TEST-03 | — | Pending |
| TEST-04 | — | Pending |
| TEST-05 | — | Pending |
| TEST-06 | — | Pending |
| TEST-07 | — | Pending |
| UX-01 | — | Pending |
| UX-02 | — | Pending |
| UX-03 | — | Pending |

**Coverage:**
- v1 requirements: 28 total
- Mapped to phases: 0
- Unmapped: 28 ⚠️

---
*Requirements defined: 2026-04-05*
*Last updated: 2026-04-05 after initial definition*

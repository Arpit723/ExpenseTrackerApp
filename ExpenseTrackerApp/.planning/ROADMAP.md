# Roadmap: ExpenseTrackerApp — Firebase Auth & Firestore Migration

## Overview

This roadmap migrates a working in-memory SwiftUI expense tracker to Firebase-backed authentication and persistence with full test coverage. The journey starts by extracting protocol abstractions from the existing concrete services (enabling testing without Firebase), then builds auth UI with a mock service (testable immediately), integrates the real Firebase Auth SDK, migrates data storage to Firestore with per-user scoping, and finishes with a comprehensive test suite hitting 80% coverage.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Protocol Extraction** - Extract service protocols and mock implementations to enable testing and Firebase swap
- [ ] **Phase 2: Auth Protocol and UI** - Build auth views and AuthViewModel using mock service, testable without Firebase
- [ ] **Phase 3: Firebase SDK Integration** - Add Firebase SDK and implement real FirebaseAuthService behind existing protocol
- [ ] **Phase 4: Firestore Data Layer** - Implement FirestoreDataService with per-user scoping and security rules
- [ ] **Phase 5: Testing and Coverage** - Full test suite for all ViewModels and Services, hitting 80% coverage target

## Phase Details

### Phase 1: Protocol Extraction
**Goal**: All ViewModels depend on protocols, not concrete services, enabling isolated testing and future Firebase swap
**Depends on**: Nothing (first phase)
**Requirements**: ARCH-01, ARCH-02, ARCH-03, ARCH-04
**Success Criteria** (what must be TRUE):
  1. All ViewModels accept service protocols via init parameters instead of accessing DataService.shared directly
  2. DataServiceProtocol declares all CRUD operations and computed properties that DataService currently exposes
  3. AuthServiceProtocol declares register, login, logout, and auth state listener methods
  4. MockDataService and MockAuthService conform to their respective protocols and are usable in tests
  5. App builds and runs identically to before — no behavior changes, only structural refactoring
**Plans**: TBD

Plans:
- [ ] 01-01: Extract DataServiceProtocol from DataService and wire ViewModels
- [ ] 01-02: Define AuthServiceProtocol and create MockDataService/MockAuthService

### Phase 2: Auth Protocol and UI
**Goal**: Users can see and interact with login, register, and auth gate screens using a mock auth service
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-05, AUTH-06, AUTH-08, UX-01, UX-02, UX-03
**Success Criteria** (what must be TRUE):
  1. Unauthenticated users see a login screen with email and password fields
  2. User can navigate to a registration form with Name, Gender, Phone Number, Email, and Password fields
  3. Loading spinners appear and buttons disable during auth operations (login, register, logout)
  4. Invalid inputs show inline validation errors (email format, password strength, required fields)
  5. Auth errors display user-facing alert messages (wrong password, email in use, network error)
  6. Root view shows auth screens or main app based on auth state without a login screen flash
**Plans**: TBD
**UI hint**: yes

Plans:
- [ ] 02-01: Build AuthViewModel with three-state auth model and error mapping
- [ ] 02-02: Build LoginView and RegisterView with inline validation and loading states
- [ ] 02-03: Build AuthGateView and wire root navigation with mock auth service

### Phase 3: Firebase SDK Integration
**Goal**: Real Firebase Authentication works end-to-end — register, login, logout, session persistence — behind the existing protocol
**Depends on**: Phase 2
**Requirements**: ARCH-05, AUTH-04, AUTH-07
**Success Criteria** (what must be TRUE):
  1. User can register with email/password and the account appears in Firebase Auth console
  2. Registration creates a Firestore profile document at users/{uid}/profile with Name, Gender, Phone, Email
  3. User can log in and their session persists across app kills and relaunches
  4. User can log out and is returned to the login screen with all local state cleared
  5. FirebaseAuthService conforms to AuthServiceProtocol — no ViewModel or View changes needed
**Plans**: TBD

Plans:
- [ ] 03-01: Add Firebase SDK via SPM and configure FirebaseApp in app entry
- [ ] 03-02: Implement FirebaseAuthService conforming to AuthServiceProtocol
- [ ] 03-03: Wire FirebaseAuthService into production app and verify end-to-end

### Phase 4: Firestore Data Layer
**Goal**: User transactions persist in Firestore scoped per user UID, with all existing CRUD and dashboard features working against real data
**Depends on**: Phase 3
**Requirements**: ARCH-06, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):
  1. Transactions added by an authenticated user appear in Firestore at users/{uid}/transactions
  2. Dashboard balance, monthly income, and monthly expenses calculate correctly from Firestore-backed data
  3. Existing transaction list (add, edit, delete, search, filter) works identically with Firestore as it did in-memory
  4. User profile data is stored at users/{uid}/profile and loads on login
  5. Firestore security rules enforce that users can only read/write their own data
**Plans**: TBD

Plans:
- [ ] 04-01: Implement FirestoreDataService conforming to DataServiceProtocol
- [ ] 04-02: Write and deploy Firestore security rules with per-user isolation
- [ ] 04-03: Wire FirestoreDataService into production app and migrate existing behavior

### Phase 5: Testing and Coverage
**Goal**: All ViewModels and Services have comprehensive unit tests with 80% code coverage, verifying correctness of every code path
**Depends on**: Phase 4
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07
**Success Criteria** (what must be TRUE):
  1. AuthViewModel tests cover registration validation, login flow, logout flow, error mapping, and state transitions
  2. DashboardViewModel, TransactionViewModel, and SettingsViewModel tests cover all business logic with mock services
  3. DataService and AuthService protocol conformance tests verify mock implementations behave correctly
  4. Code coverage on ViewModels and Services reaches 80% as reported by Xcode
  5. All tests pass consistently without flakiness or Firebase SDK dependency
**Plans**: TBD

Plans:
- [ ] 05-01: Write ViewModel unit tests (Auth, Dashboard, Transaction, Settings)
- [ ] 05-02: Write Service unit tests and verify 80% coverage target

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Protocol Extraction | 0/2 | Not started | - |
| 2. Auth Protocol and UI | 0/3 | Not started | - |
| 3. Firebase SDK Integration | 0/3 | Not started | - |
| 4. Firestore Data Layer | 0/3 | Not started | - |
| 5. Testing and Coverage | 0/2 | Not started | - |

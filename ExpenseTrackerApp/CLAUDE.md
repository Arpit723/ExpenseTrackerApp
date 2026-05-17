# CLAUDE.md

## Project Overview

Simple SwiftUI iOS app for adding and recording daily transactions (income/expenses) with Firebase Auth and Firestore persistence. Focus is quick transaction entry and reliable record-keeping. Uses MVVM architecture with protocol-based services for testability. Firebase Auth for user authentication, Firestore for per-user data persistence. Receipt photos deferred to future scope.

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
├── ExpenseTrackerAppApp.swift           # @main entry — Firebase config, injects AuthViewModel + DataService
├── Models/
│   ├── Transaction.swift                # Amount: +income, -expense; date grouping helpers; Codable
│   ├── Category.swift                   # 12 built-in categories with icons/colors; Codable
│   └── UserProfile.swift               # uid, email, fullName, birthDate, phone, preferences; Codable
├── Protocols/
│   ├── AuthServiceProtocol.swift        # Auth operations + AuthState enum + MockAuthService (#if DEBUG)
│   └── DataServiceProtocol.swift        # Data CRUD, totals, grouping (async throws)
├── ViewModels/                          # All @MainActor ObservableObject
│   ├── AuthViewModel.swift              # Auth state, login/register/logout/resetPassword/deleteAccount
│   ├── DashboardViewModel.swift         # Balance, income, expenses, recent transactions
│   ├── TransactionViewModel.swift       # Filtering (all/income/expense), sorting, search
│   └── SettingsViewModel.swift          # Currency management
├── Views/
│   ├── MainTabView.swift                # 3 tabs: Dashboard, Transactions, Settings + FAB
│   ├── Auth/
│   │   ├── LoginView.swift              # Email/password login, forgot password
│   │   └── RegisterView.swift           # Full registration form (6 fields)
│   ├── Dashboard/DashboardView.swift
│   ├── Transactions/
│   │   ├── TransactionsView.swift       # Date-grouped list with search & filter
│   │   └── AddTransactionView.swift     # Add/edit transaction sheet
│   ├── Settings/
│   │   └── SettingsView.swift           # Currency, logout, delete account
│   └── Components/
│       ├── CategoryPickerGrid.swift     # Category selection grid
│       ├── TransactionRow.swift         # Transaction list item
│       └── QuickActionButton.swift      # Quick action buttons & FAB
├── Services/
│   ├── DataService.swift                # In-memory data store — CRUD, computed totals (testing)
│   ├── FirebaseAuthService.swift        # Firebase Auth: login, register, logout, resetPassword, deleteAccount
│   ├── FirestoreDataService.swift       # Firestore: per-user CRUD, real-time listener, batch delete
│   └── LocalAuthService.swift           # In-memory auth fallback (no GoogleService-Info.plist)
├── Utils/
│   ├── AppError.swift                   # Unified error type: auth, network, data, validation + Firebase mapping
│   ├── Constants.swift                  # Layout values, Notification.Name extensions, quick amounts
│   ├── CurrencyManager.swift            # Shared observable currency state (injected via EnvironmentObject)
│   └── Extensions/
│       ├── Color+Theme.swift            # App colors, hex init
│       ├── Date+Extensions.swift        # startOfMonth, isThisMonth, dateGroupTitle
│       └── Double+Currency.swift        # Currency formatting helpers
ExpenseTrackerAppTests/
├── Mocks/
│   ├── MockAuthService.swift            # Test mock for AuthServiceProtocol
│   └── MockDataService.swift            # Test mock for DataServiceProtocol
├── AppErrorTests.swift                  # AppError + Firebase error mapping tests
├── AuthViewModelTests.swift             # AuthViewModel unit tests
├── DashboardViewModelTests.swift        # DashboardViewModel unit tests
├── TransactionViewModelTests.swift      # TransactionViewModel unit tests
├── SettingsViewModelTests.swift         # SettingsViewModel unit tests
├── FirebaseAuthServiceTests.swift       # FirebaseAuthService tests
├── FirestoreDataServiceTests.swift      # FirestoreDataService tests
└── ProtocolSmokeTests.swift             # Protocol conformance smoke tests
```

## Architecture

### Data Flow

1. **App entry** (`ExpenseTrackerAppApp`): configures Firebase if `GoogleService-Info.plist` exists, falls back to `LocalAuthService` otherwise; creates `AuthViewModel` with injected `AuthServiceProtocol`
2. **Auth gate**: observes `AuthViewModel.authState` — shows `AuthGateView` (Login/Register) or `MainTabView`
3. **AuthViewModel**: reactive auth state (`.loading`, `.authenticated`, `.unauthenticated`), delegates to `AuthServiceProtocol`
4. **ViewModels**: receive data service via dependency injection; own `@Published` display state
5. **Views**: observe `@StateObject` ViewModels

### Service Layer

**AuthServiceProtocol** — implemented by:
- `FirebaseAuthService` — production: uses `FirebaseAuth` SDK for real authentication
- `LocalAuthService` — fallback: in-memory auth when `GoogleService-Info.plist` is absent
- `MockAuthService` — testing: `#if DEBUG` mock in `AuthServiceProtocol.swift`

**DataServiceProtocol** — implemented by:
- `FirestoreDataService` — production: Firestore per-user CRUD, real-time snapshot listener, batch delete
- `DataService` — testing: in-memory singleton with sample data

Key behaviors:
- Async CRUD operations on transactions (`async throws`)
- Computed totals: `totalBalance`, `totalIncomeThisMonth`, `totalExpensesThisMonth`
- `groupedTransactions()` returns date-grouped list
- Firestore snapshot listener for real-time updates
- Firestore is source of truth for currency

### Error Handling

**AppError** enum (`Utils/AppError.swift`) — unified error type:
- `AuthError` — invalidCredentials, emailInUse, weakPassword, passwordMismatch, userNotFound, sessionExpired
- `NetworkError` — noConnection, timeout, serverError
- `DataError` — saveFailed, loadFailed, deleteFailed
- `ValidationError` — emptyField, invalidEmail, invalidPassword, futureDate, invalidPhone

Error flow: Service throws `AppError` → ViewModel catches, sets `@Published var error: AppError?` → View shows alert.
Firebase errors mapped to `AppError` via `AppError.from(firebaseError:)`.

### Notification-Based Updates

Defined in `Constants.swift` as `Notification.Name` extensions:

| Notification | Trigger |
|---|---|
| `transactionAdded` | New transaction created |
| `transactionUpdated` | Transaction edited |
| `transactionDeleted` | Transaction removed |

ViewModels listen to these and recalculate `@Published` properties.

## Test-Driven Development (TDD) — MANDATORY

**Write tests BEFORE writing implementation code. As much as possible.**

Every feature, bug fix, or refactoring must follow this cycle:

1. **RED** — Write a failing test that describes the desired behavior
2. **GREEN** — Write the minimum implementation code to make the test pass
3. **REFACTOR** — Clean up the code while keeping tests green

### Rules

- **Never implement a feature without a test first.** If a ViewModel method needs to exist, write a test that calls it first.
- **Before writing any important feature, write unit tests first.** No exceptions for significant features like auth, data persistence, transaction CRUD, or any Firebase integration.
- **Never skip the RED step.** Run the test and confirm it fails before writing implementation.
- **Protocol mocks come first.** Before implementing a service, define its protocol and write mock-based tests.
- **Coverage target: 80%+** on ViewModels and Services (measured by `xcodebuild test`).
- **All new files must have corresponding test files.** One test file per source file minimum.
- **Use `/xctest-generator` skill** when generating test scaffolding.

### When TDD applies

| Scenario | Action |
|----------|--------|
| New ViewModel method | Write test for expected output given input, then implement |
| New Service method | Write test with mock dependency, then implement |
| Bug fix | Write test that reproduces the bug (must fail), then fix |
| Refactoring | Tests must already exist and be green before refactoring |
| Model changes | Write Codable round-trip and computed property tests first |

### Exceptions

- Pure SwiftUI view layout changes (no logic) may skip TDD
- Quick one-line fixes where writing a test would be disproportionate (use judgment)

## Coding Conventions

- **SwiftUI + Combine**: use `@Published` for reactive state; `async/await` for service calls
- **Models**: structs with `UUID` ids, `Codable` + `Hashable` conformance, `categoryId` reference on Transaction
- **ViewModels**: `@MainActor`, `ObservableObject`, receive services via init injection
- **Services**: `@MainActor`, `ObservableObject`, conform to protocols (`AuthServiceProtocol`, `DataServiceProtocol`)
- **Errors**: all service methods `async throws` → throw `AppError` → ViewModel catches and sets `@Published var error`
- **Colors**: use theme colors from `Color+Theme.swift` (`Color.appPrimary`, `Color.appSuccess`, etc.), never hardcode hex in views
- **Layout constants**: use `Constants.Layout.*` and `Constants.Animation.*`, avoid magic numbers
- **Date formatting**: use `Date+Extensions` helpers, keep formatters static for performance
- **Design tokens**: follow typography scale from SRS section 6.5 (displayLarge 36pt bold, titleLarge 28pt bold, etc.)
- **Motion**: use `Constants.Animation.*` values, always respect `@Environment(\.accessibilityReduceMotion)`
- **Accessibility**: all interactive elements need `accessibilityLabel`, income/expense colors must have +/- prefix, minimum 44pt touch targets

## Design System

Defined in `docs/SRS.md` sections 6.5-6.9:
- **Typography**: SF Pro system font, scale from 12pt (caption) to 48pt (amount input)
- **Motion**: 0.1s-0.35s durations, spring/easeInOut curves, reduced motion support required
- **Components**: 16pt corner radius for cards/inputs/buttons, no decorative shadows, rely on background contrast
- **Spacing**: 4pt base unit grid (xs=4, sm=8, md=16, lg=20, xl=24)
- **Accessibility**: VoiceOver labels, Dynamic Type xSmall-xxxLarge, WCAG AA contrast, colorblind-safe patterns

## Key Model Semantics

- **Transaction.amount**: positive = income, negative = expense
- **Category**: 12 built-in categories; `isSystem` flag marks non-deletable ones (Income, Transfer)
- **UserProfile**: uid (Firebase Auth UID), email, fullName, birthDate, phone, preferences
- **AppError**: unified error with auth/network/data/validation sub-types; Firebase error mapping
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

<!-- GSD:project-start source:PROJECT.md -->
## Project

**ExpenseTrackerApp — Firebase Auth & Firestore Migration**

A SwiftUI iOS expense tracker with Firebase Authentication (login/register/logout/password reset/delete account) and Firebase Firestore (per-user persistence). Uses MVVM architecture with protocol-based services for testability. Includes comprehensive unit tests with mock-based isolation.

**Core Value:** Users can securely log in, have their transactions persisted across sessions, and trust the app works correctly through automated tests.

### Constraints

- **Tech Stack**: Swift 5.0, SwiftUI, iOS 18.5+, Firebase SDK via SPM
- **Architecture**: MVVM with protocol-based services for DI and testability
- **Testing**: XCTest with protocol mocks, 80% coverage target on ViewModels/Services
- **No external UI libraries**: All SwiftUI native
- **Single currency per user**: No multi-currency support
- **Single balance**: All transactions tracked against one total per user
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Swift 5.0 - All application code: models, views, view models, services, utilities
## Runtime
- iOS 18.5+ (minimum deployment target: `IPHONEOS_DEPLOYMENT_TARGET = 18.5`)
- Apple platforms only (iOS simulator and device)
- SwiftUI lifecycle app (`@main` App protocol)
- Swift Package Manager (SPM) for Firebase SDK
## Frameworks
- SwiftUI - All UI views and layout; app entry point uses `Scene`/`WindowGroup` pattern
- Combine - Reactive bindings in ViewModels (`@Published`, `NotificationCenter.default.publisher`, `sink`, `AnyCancellable`)
- Foundation - Data models, formatting, date calculations, `NotificationCenter`
- XCTest - Unit test framework with mock-based isolation
- Firebase Core - SDK bootstrap and configuration
- FirebaseAuth - Email/Password authentication, state listener, password reset
- FirebaseFirestore - Per-user data persistence, real-time snapshots, offline cache
## Key Dependencies
- Firebase iOS SDK (latest, via SPM) — `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`
- `GoogleService-Info.plist` — Firebase config (not in version control; app falls back to `LocalAuthService` without it)
## Configuration
- `Info.plist` contains `UIBackgroundModes` with `remote-notification`
- `GoogleService-Info.plist` — Firebase project config (required for production auth/Firestore)
- All layout/animation configuration in `Constants.swift`
- Three build targets: `ExpenseTrackerApp`, `ExpenseTrackerAppTests`, `ExpenseTrackerAppUITests`
## Platform Requirements
- macOS with Xcode 16+
- iOS 18.5 Simulator (iPhone 16 is the development target device)
- iPhone / iPad running iOS 18.5+
## Data Persistence
- **Production**: Firebase Firestore per-user storage (`users/{uid}/transactions/{txId}`)
- **Testing**: In-memory `DataService` singleton with `@Published` arrays
- `CurrencyManager` caches currency locally via UserDefaults and publishes changes via `@Published`
- Models conform to `Codable` for Firestore serialization
- Offline: Firestore SDK caches locally, queues writes for sync
- Real-time updates via Firestore snapshot listener in `FirestoreDataService`
## Key Architecture Decisions
- **MVVM pattern**: `@MainActor ObservableObject` ViewModels with `@Published` properties
- **Firebase SDK**: FirebaseAuth + FirebaseFirestore via SPM
- **SwiftUI only**: No UIKit/Storyboard usage
- **Reactive updates**: Combine-based `NotificationCenter` subscriptions in ViewModels
- **Protocol-based services**: `AuthServiceProtocol` and `DataServiceProtocol` with multiple implementations
- **Service fallback**: App auto-detects `GoogleService-Info.plist`; uses `LocalAuthService` when absent
- **Unified error handling**: `AppError` enum with Firebase error mapping
- **Swift previews**: `#Preview` macros used in views for Xcode Canvas previews
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- PascalCase matching the primary type/struct/enum they define: `DashboardView.swift`, `TransactionRow.swift`, `Color+Theme.swift`
- Extensions on existing types use `Type+Extension` naming: `Color+Theme.swift`, `Date+Extensions.swift`, `Double+Currency.swift`
- One primary type per file (exceptions: small helper types like `FilterChip` embedded in the same file as the view that uses it)
- PascalCase for type names: `Transaction`, `DashboardViewModel`, `CategoryPickerGrid`
- Models are structs; ViewModels and services are classes
- camelCase for cases: `.all`, `.income`, `.expenses`, `.dateDescending`
- camelCase: `refreshData()`, `addTransaction(_:)`, `formattedAsCurrency()`
- Private helpers are extracted: `private var balanceCard: some View`, `private func saveTransaction()`
- camelCase: `totalBalance`, `selectedFilter`, `showingAddTransaction`
- Boolean state variables prefixed with `is` or `showing`: `isExpense`, `isLoading`, `showingCategoryPicker`, `showingDeleteConfirmation`
- Static let on `Constants` struct: `Constants.Layout.cornerRadius`, `Constants.Animation.default`
- Nested structs for grouping: `Constants.Layout`, `Constants.Animation`, `Constants.Colors`
- All models conform to `Identifiable`, `Codable`, `Hashable`
- UUID-based `id` property on all models
- Enums use `String` raw values and conform to `CaseIterable`, `Codable`
## Code Style
- No external formatter detected (Swift default indentation)
- Xcode-generated file headers: `//\n//  FileName.swift\n//  ExpenseTrackerApp\n//\n//  Created by Arpit Parekh on 28/03/26.\n//`
- Consistent 4-space indentation
- No linter configured (no SwiftLint, no custom build phase linting)
- Heavy use of `// MARK: - Section Name` throughout all files
- Pattern: `// MARK: - Published Properties`, `// MARK: - Dependencies`, `// MARK: - Initialization`, `// MARK: - Computed Properties`, `// MARK: - CRUD Operations`
## Error Handling
- `AppError` enum with sub-types: `AuthError`, `NetworkError`, `DataError`, `ValidationError`
- All service methods use `async throws` and throw `AppError`
- Firebase errors mapped via `AppError.from(firebaseError:)` in `AppError.swift`
- ViewModels catch errors and set `@Published var error: AppError?`
- Views show alerts via `.alert(item: $viewModel.error)`
- Guard-let for early returns in validation methods
- Form validation via computed `isValidForm` property
## Import Organization
- Framework imports first: `SwiftUI`, `Foundation`, `Combine`
- Firebase imports: `FirebaseCore`, `FirebaseAuth`, `FirebaseFirestore`
- No third-party imports beyond Firebase SDK
## Logging
- No logging statements in production code
- Debugging relies on Xcode previews and SwiftUI preview macros
- `#Preview` blocks at the bottom of every view file
## Comments
- `// MARK: -` comments are used extensively for navigation
- SRS requirement references inline: `// MARK: - Income/Expense Toggle (FR-2.1)`
- Otherwise minimal comments — code is self-documenting
## Function Design
- View body properties decomposed into extracted sub-views (computed properties returning `some View`)
- Action functions are short and focused: `saveTransaction()`, `deleteTransaction(_:)`
- Service methods use `async throws` returning concrete types
- Helper lookups return optionals: `func category(for id: UUID) -> Category?`
- Computed properties for derived data: `var isExpense: Bool`, `var displayAmount: String`
## Module Design
- Each file exports one primary type
- Small helper types defined in the same file as the primary view that uses them
- No barrel files or module index files
## Architecture Patterns
- Views: SwiftUI `View` structs in `Views/` directory
- ViewModels: `@MainActor ObservableObject` classes in `ViewModels/` directory
- Models: Value-type structs in `Models/` directory
- Services: `@MainActor ObservableObject` classes in `Services/` directory
- Views create ViewModels via `@StateObject private var viewModel = SomeViewModel()`
- ViewModels receive services via init injection with protocol type: `init(authService: any AuthServiceProtocol)`
- `@Published` properties on ViewModels drive view updates
- `DataService` injected at app root via `.environmentObject(dataService)`
- `AuthViewModel` injected at app root via `@StateObject`
- Services post `Notification.Name` notifications after CRUD operations
- ViewModels subscribe via Combine publishers in `setupBindings()`
- Always use theme colors from `Color+Theme.swift`: `Color.appPrimary`, `Color.appSuccess`, `Color.appDanger`
- Category colors stored as hex strings, converted via `Color(hex:)` in `Category.swift`
- Use `Constants.Layout.*` for spacing, padding, corner radius
- Use `Constants.Animation.*` for animation durations
- Avoid magic numbers in views
- Use `Date+Extensions` helpers: `.relativeString`, `.shortDate`, `.timeOnly`, `.monthYear`
- Use `Double.formattedAsCurrency(code:)` extension from `Double+Currency.swift`, passing `currencyManager.currencyCode`
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## 1. Architectural Pattern: MVVM

```
Views (SwiftUI)
  ↓ @StateObject
ViewModels (@MainActor, ObservableObject)
  ↓ protocol injection
Services (AuthServiceProtocol, DataServiceProtocol)
  ↓
Firebase SDK / In-Memory
```

### Layer Boundaries
| Layer | Files | Responsibility |
|-------|-------|----------------|
| **Views** | `Views/**/*.swift` | Declarative UI, user interaction capture |
| **ViewModels** | `ViewModels/**/*.swift` | Business logic, state transformation, service coordination |
| **Protocols** | `Protocols/*.swift` | Service abstractions for DI and testability |
| **Services** | `Services/*.swift` | Data storage, auth, CRUD, Firebase integration |
| **Models** | `Models/*.swift` | Data structures, Codable conformance |
| **Utils** | `Utils/**/*.swift` | Shared extensions, constants, AppError |

## 2. Service Implementations

### AuthServiceProtocol
| Implementation | When Used |
|----------------|-----------|
| `FirebaseAuthService` | Production — `GoogleService-Info.plist` present |
| `LocalAuthService` | Development — no Firebase config |
| `MockAuthService` | Unit tests (`#if DEBUG`) |

### DataServiceProtocol
| Implementation | When Used |
|----------------|-----------|
| `FirestoreDataService` | Production — per-user Firestore CRUD |
| `DataService` | Testing — in-memory singleton |

## 3. Data Flow

1. `ExpenseTrackerAppApp` → detects `GoogleService-Info.plist` → creates `FirebaseAuthService` or `LocalAuthService`
2. `AuthViewModel(authService:)` → `setupAuthListener()` → publishes `AuthState`
3. Auth gate observes `authState` → Login/Register or MainTabView
4. ViewModels receive `DataServiceProtocol` via init injection
5. `FirestoreDataService.loadData()` → sets up Firestore snapshot listener
6. CRUD operations → post `NotificationCenter` events → ViewModels recalculate

## 4. Navigation Architecture
- **Auth flow**: NavigationStack with LoginView → RegisterView
- **Tab-based**: 3 tabs (Dashboard, Transactions, Settings)
- **Sheet flows**: Add/Edit Transaction, Category Picker
- **Settings**: includes Logout and Delete Account

## 5. State Management
| Mechanism | Usage |
|-----------|-------|
| `@StateObject` | ViewModels owned by views |
| `@Published` | ViewModel → View reactivity |
| `@EnvironmentObject` | DataService injected from app root |
| `@AppStorage` | Currency cached locally (backed by CurrencyManager) |
| `NotificationCenter` | Cross-ViewModel updates |
| `Combine` | Debounced filter pipeline in TransactionViewModel |

## 6. Error Handling
- **AppError** enum: unified error type with auth, network, data, validation cases
- Error flow: Service throws AppError → ViewModel catches, sets `@Published var error: AppError?` → View shows alert
- All ViewModels include `@Published var error: AppError?` and `@Published var isLoading: Bool`
- Firebase errors mapped to AppError via `AppError.from(firebaseError:)` in service layer
- Form validation: `isValidForm` computed property gates save button

## 7. Cross-Cutting Concerns
### 7.1 Theming
- App locked to light mode via `.preferredColorScheme(.light)` on root view
- `Color+Theme.swift` defines app color palette
- Colors use semantic names (`.appPrimary`, `.appSuccess`, `.appDanger`)
### 7.2 Date Handling
- `Date+Extensions.swift` provides grouping helpers (`isToday`, `isThisWeek`, `isThisMonth`)
- `Transaction.dateGroupTitle` returns section headers for list grouping
- Group order: Today → Yesterday → This Week → This Month → Older
### 7.3 Currency Formatting
- `Double+Currency.swift` — `formattedAsCurrency(code:)` using NumberFormatter
- `Transaction.formattedAmount(currencyCode:)` and `displayAmount(currencyCode:)` for UI display
- `CurrencyManager` injected as `@EnvironmentObject` — views pass `currencyManager.currencyCode` to formatters
- Currency changes propagate instantly across all views via `@Published` properties
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

| Skill | Description | Path |
|-------|-------------|------|
| claude-api | "Build apps with the Claude API or Anthropic SDK. TRIGGER when: code imports `anthropic`/`@anthropic-ai/sdk`/`claude_agent_sdk`, or user asks to use Claude API, Anthropic SDKs, or Agent SDK. DO NOT TRIGGER when: code imports `openai`/other AI SDK, general programming, or ML/data-science tasks." | `.claude/skills/claude-api/SKILL.md` |
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- gstack:start -->
## gstack

Use the `/browse` skill from gstack for **all web browsing** tasks. Never use `mcp__claude-in-chrome__*` tools.

### Available skills

`/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`
<!-- gstack:end -->

## Skill routing

When the user's request matches an available skill, ALWAYS invoke it using the Skill
tool as your FIRST action. Do NOT answer directly, do NOT use other tools first.
The skill has specialized workflows that produce better results than ad-hoc answers.

Key routing rules:
- Product ideas, "is this worth building", brainstorming → invoke office-hours
- Bugs, errors, "why is this broken", 500 errors → invoke investigate
- Ship, deploy, push, create PR → invoke ship
- QA, test the site, find bugs → invoke qa
- Code review, check my diff → invoke review
- Update docs after shipping → invoke document-release
- Weekly retro → invoke retro
- Design system, brand → invoke design-consultation
- Visual audit, design polish → invoke design-review
- Architecture review → invoke plan-eng-review
- Save progress, checkpoint, resume → invoke checkpoint
- Code quality, health check → invoke health

<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->

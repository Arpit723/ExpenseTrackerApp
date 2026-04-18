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

1. **App entry** (`ExpenseTrackerAppApp`): checks Firebase Auth state, shows AuthGateView or MainTabView
2. **AuthViewModel**: observes Firebase Auth state listener, publishes `AuthState` (.loading, .authenticated, .unauthenticated)
3. **ViewModels**: receive data service via dependency injection; own `@Published` display state
4. **Views**: observe `@StateObject` ViewModels

### Data Service

`FirestoreDataService` (production) implements `DataServiceProtocol` with Firebase Firestore. Replaces in-memory `DataService` at injection point. `DataService` kept for testing only.

Key behaviors:
- Async CRUD operations on transactions
- Computed totals: `totalBalance`, `totalIncomeThisMonth`, `totalExpensesThisMonth`
- `groupedTransactions()` returns date-grouped list
- Pagination: Dashboard loads 10 recent, Transaction list uses 50-item pages
- Firestore is source of truth for currency/theme (section 7.7 of SRS)

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

- **SwiftUI + Combine**: use `@Published` for reactive state; no external dependencies
- **Models**: structs with `UUID` ids, `categoryId` reference on Transaction
- **ViewModels**: `@MainActor`, `ObservableObject`, receive data service from environment
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

A simple SwiftUI iOS expense tracker that currently records daily transactions (income/expenses) in-memory. This project adds Firebase Authentication (login/register/logout), migrates data storage to Firebase Firestore (per-user persistence), and establishes unit testing infrastructure. The app uses MVVM architecture with protocol-based services for testability.

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
- XML - `Info.plist` configuration (remote-notification background mode only)
- Ruby / YAML - Not used; no fastlane active configuration despite `.gitignore` entry
## Runtime
- iOS 18.5+ (minimum deployment target: `IPHONEOS_DEPLOYMENT_TARGET = 18.5`)
- Apple platforms only (iOS simulator and device)
- SwiftUI lifecycle app (`@main` App protocol)
- Swift Package Manager (SPM) - configured in Xcode project but **zero external packages** currently installed
- No CocoaPods, Carthage, or Accio dependencies
- No `Package.swift` file (Xcode-managed SPM only)
## Frameworks
- SwiftUI - All UI views and layout; app entry point uses `Scene`/`WindowGroup` pattern
- Combine - Reactive bindings in ViewModels (`@Published`, `NotificationCenter.default.publisher`, `sink`, `AnyCancellable`)
- Foundation - Data models, formatting, date calculations, `NotificationCenter`
- XCTest - Unit test framework (`ExpenseTrackerAppTests/ExpenseTrackerAppTests.swift`)
- XCUITest - UI test framework (`ExpenseTrackerAppUITests/`)
- Xcode 16+ (project format is `.xcodeproj`, no `.xcworkspace`)
- `xcodebuild` CLI for CI builds: `xcodebuild -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'`
## Key Dependencies
- None. This is a zero-dependency app. All functionality is built on Apple first-party frameworks only.
- `@AppStorage` - UserDefaults wrapper for persistent settings (currency, theme); see `SettingsViewModel.swift`
- `NotificationCenter` - Internal event bus for transaction CRUD notifications; see `Constants.swift`
## Configuration
- No `.env` files present
- `Info.plist` contains only `UIBackgroundModes` with `remote-notification` (currently unused)
- No `GoogleService-Info.plist` (Firebase not integrated)
- All configuration is code-based in `Constants.swift` and `DataService.swift`
- Build config in `ExpenseTrackerApp.xcodeproj/project.pbxproj`
- Swift version: 5.0 (all targets)
- iOS deployment target: 18.5 (all targets)
- Three build targets:
## Platform Requirements
- macOS with Xcode 16+
- iOS 18.5 Simulator (iPhone 16 is the development target device)
- No external tooling required
- iPhone / iPad running iOS 18.5+
- Not configured for App Store distribution yet (no archive/scheme settings for release)
- No CI/CD pipeline configured
## Data Persistence
- **Target**: Firebase Firestore per-user storage (`users/{uid}`, `users/{uid}/transactions/{txId}`)
- **Current**: In-memory `DataService` singleton with `@Published` arrays (to be replaced by FirestoreDataService)
- `@AppStorage` caches currency/theme locally; Firestore is source of truth
- Models conform to `Codable` for Firestore serialization
- Offline: Firestore SDK caches locally, queues writes for sync
## Key Architecture Decisions
- **MVVM pattern**: `@MainActor ObservableObject` ViewModels with `@Published` properties
- **No external dependencies**: Entirely Apple frameworks
- **SwiftUI only**: No UIKit/Storyboard usage
- **Reactive updates**: Combine-based `NotificationCenter` subscriptions in ViewModels
- **Protocol-based data layer**: `DataServiceProtocol` with async methods; `FirestoreDataService` in production, `DataService` for testing
- **Swift previews**: `#Preview` macros used in views for Xcode Canvas previews
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Naming Patterns
- PascalCase matching the primary type/struct/enum they define: `DashboardView.swift`, `TransactionRow.swift`, `Color+Theme.swift`
- Extensions on existing types use `Type+Extension` naming: `Color+Theme.swift`, `Date+Extensions.swift`, `Double+Currency.swift`
- One primary type per file (exceptions: small helper types like `FilterChip` embedded in the same file as the view that uses it)
- PascalCase: `Transaction`, `DashboardViewModel`, `CategoryPickerGrid`
- Models are structs; ViewModels and services are classes
- PascalCase for type names: `TransactionFilter`, `TransactionSort`, `AppTheme`
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
- Used in every file to separate logical sections
- View bodies use `// MARK: - Section Name` to delineate extracted view properties
- Pattern: `// MARK: - Published Properties`, `// MARK: - Dependencies`, `// MARK: - Initialization`, `// MARK: - Computed Properties`, `// MARK: - Helper Methods`, `// MARK: - CRUD Operations`
## Import Organization
## Error Handling
- No formal error handling (`throws`, `Result`, `Error` types) anywhere in the codebase
- Optional chaining for nullable values: `transaction.payee?.localizedCaseInsensitiveContains(searchText)`
- Nil coalescing for fallbacks: `Color(hex: color) ?? .gray`, `formatter.string(from:) ?? "$0.00"`
- Guard-let for early returns in action methods: `guard let amountValue = Double(amount), let category = selectedCategory, amountValue > 0 else { return }`
- `try?` used for optional async work: `try? await Task.sleep(nanoseconds: 300_000_000)`
- Form validation via computed `isValidForm` property checking `amountValue > 0 && selectedCategory != nil`
- Save button disabled when form is invalid: `.disabled(!isValidForm)`
## Logging
- No logging statements anywhere in the codebase
- Debugging relies on Xcode previews and SwiftUI preview macros
- `#Preview` blocks at the bottom of every view file
## Comments
- `// MARK: -` comments are used extensively for navigation
- SRS requirement references inline: `// MARK: - Income/Expense Toggle (FR-2.1)`, `// MARK: - Recent Transactions (last 10 -- FR-1.3)`
- Section comments explain business rules: `// Search across payee and notes (FR-2.5)`, `// Filter by type (FR-2.6)`
- Otherwise minimal comments -- code is self-documenting
- Not used. No doc comments on any function, property, or type.
## Function Design
- View body properties are decomposed into extracted sub-views (computed properties returning `some View`)
- Example from `ExpenseTrackerApp/Views/Dashboard/DashboardView.swift`:
- Action functions are short and focused: `saveTransaction()`, `deleteTransaction(_:)`
- ViewModels return concrete types, not optionals, for UI state
- Helper lookups return optionals: `func category(for id: UUID) -> Category?`
- Computed properties for derived data: `var isExpense: Bool`, `var displayAmount: String`
## Module Design
- Each file exports one primary type
- Small helper types (like `FilterChip`, `CategoryIconView`, `FloatingAddButton`, `QuickAmountButton`, `TabBarButton`, `CategoryPickerSheet`) are defined in the same file as the primary view that uses them
- No barrel files or module index files
- Not used. All imports reference specific types via the module `ExpenseTrackerApp`
## Architecture Patterns
- Views: SwiftUI `View` structs in `Views/` directory
- ViewModels: `@MainActor ObservableObject` classes in `ViewModels/` directory
- Models: Value-type structs in `Models/` directory
- Views create ViewModels via `@StateObject private var viewModel = SomeViewModel()`
- ViewModels receive `DataService` via dependency injection with default parameter: `init(dataService: DataService = .shared)`
- `@Published` properties on ViewModels drive view updates
- `DataService` injected at app root via `.environmentObject(dataService)` in `ExpenseTrackerApp/ExpenseTrackerAppApp.swift`
- `DataService` posts `Notification.Name` notifications after CRUD operations
- ViewModels subscribe via Combine publishers in `setupBindings()`
- Views also subscribe directly via `.onReceive()` modifier
- Notification names defined as `Notification.Name` extensions in `ExpenseTrackerApp/Utils/Constants.swift`
- Always use theme colors from `Color+Theme.swift`: `Color.appPrimary`, `Color.appSuccess`, `Color.appDanger`, etc.
- Never hardcode hex values in views -- use `Color(hex:)` initializer or theme constants
- Category colors stored as hex strings, converted via `Color(hex:)` in `Category.swift`
- Use `Constants.Layout.*` for spacing, padding, corner radius
- Use `Constants.Animation.*` for animation durations
- Avoid magic numbers in views
- Use `Date+Extensions` helpers: `.relativeString`, `.shortDate`, `.timeOnly`, `.monthYear`
- Custom formatting: `.formatted(with: "MMM d, yyyy")`
- Note: `DateFormatter` is created per-call in extensions (not cached in static property) -- a potential performance concern
- Use `Double.formattedAsCurrency()` extension from `ExpenseTrackerApp/Utils/Extensions/Double+Currency.swift`
- Default currency code is "USD"
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## 1. Architectural Pattern: MVVM
```
```
### Layer Boundaries
| Layer | Files | Responsibility |
|-------|-------|----------------|
| **Views** | `Views/**/*.swift` | Declarative UI, user interaction capture |
| **ViewModels** | `ViewModels/**/*.swift` | Business logic, state transformation, service coordination |
| **Services** | `Services/DataService.swift` | Data storage, CRUD, computed aggregates |
| **Models** | `Models/**/*.swift` | Data structures, validation helpers |
| **Utils** | `Utils/**/*.swift` | Shared extensions, constants |
## 2. Data Flow
### 2.1 App Initialization
```
```
### 2.2 View → ViewModel → Service Flow
```
```
### 2.3 Notification-Based Updates
```
```
- `.transactionAdded`
- `.transactionUpdated`
- `.transactionDeleted`
### 2.4 Reactive Filter Pipeline (TransactionViewModel)
```
```
## 3. Key Abstractions
### 3.1 DataService (Singleton)
```swift
```
### 3.2 Models (Value Types)
- `Transaction` — amount (signed), categoryId, date, payee, notes, timestamps
- `Category` — name, icon (SF Symbol), color (hex), isSystem flag
- `UserProfile` — preferences (currency, theme)
- `UserPreferences` — currency code/symbol, AppTheme enum
- `AppTheme` — enum: .light, .dark, .system
### 3.3 ViewModels (Reference Types)
```swift
```
- `DashboardViewModel` — balance, monthly stats, recent transactions
- `TransactionViewModel` — filtering, sorting, search, CRUD delegation
- `SettingsViewModel` — currency/theme via @AppStorage
## 4. Navigation Architecture
### 4.1 Tab-Based Navigation
```
```
### 4.2 Sheet-Based Flows
- **Add Transaction:** Full-height sheet with form
- **Edit Transaction:** Same sheet, pre-populated from `transactionToEdit`
- **Category Picker:** Medium/large detent sheet
- **Settings:** Full NavigationStack sheet
### 4.3 Delete Flow
```
```
## 5. State Management
| Mechanism | Usage |
|-----------|-------|
| `@StateObject` | ViewModels owned by views |
| `@Published` | ViewModel → View reactivity |
| `@EnvironmentObject` | DataService injected from app root (not currently used by views directly) |
| `@AppStorage` | Currency, theme cached locally (Firestore is source of truth) |
| `NotificationCenter` | Cross-ViewModel updates (DataService → DashboardViewModel) |
| `Combine` | Debounced filter pipeline in TransactionViewModel |
## 6. Error Handling
- **AppError** enum (SRS section 7.6): unified error type with auth, network, data, validation cases
- Error flow: Service throws AppError → ViewModel catches, sets `@Published var error: AppError?` → View shows `.alert(item:)`
- All ViewModels include `@Published var error: AppError?` and `@Published var isLoading: Bool`
- Firebase errors mapped to AppError in service layer
- Form validation: `isValidForm` computed property gates save button
## 7. Cross-Cutting Concerns
### 7.1 Theming
- `Color+Theme.swift` defines app color palette
- `AppTheme` enum supports light/dark/system
- Colors use semantic names (`.appPrimary`, `.appSuccess`, `.appDanger`)
- System colors (`.appTextPrimary` = `UIColor.label`) adapt to dark mode automatically
### 7.2 Date Handling
- `Date+Extensions.swift` provides grouping helpers (`isToday`, `isThisWeek`, `isThisMonth`)
- `Transaction.dateGroupTitle` returns section headers for list grouping
- Group order: Today → Yesterday → This Week → This Month → Older
### 7.3 Currency Formatting
- `Double+Currency.swift` — `formattedAsCurrency()` using NumberFormatter
- `Transaction.formattedAmount` and `displayAmount` for UI display
- User's selected currency from SettingsViewModel stored in @AppStorage
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

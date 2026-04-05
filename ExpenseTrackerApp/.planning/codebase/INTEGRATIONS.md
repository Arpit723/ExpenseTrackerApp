# External Integrations

**Analysis Date:** 2026-04-05

## APIs & External Services

**None.** This application has zero external API integrations. All data is local and in-memory. No network requests are made.

## Data Storage

**Databases:**
- None. No Core Data, SwiftData, Realm, SQLite, or any database framework is used.
- Data lives entirely in `DataService.shared` (`ExpenseTrackerApp/Services/DataService.swift`) as in-memory `@Published` arrays.
- All transaction data is lost on app termination.

**Persistent Storage:**
- `UserDefaults` via `@AppStorage` for user preferences only:
  - `appTheme` (String: "Light" | "Dark" | "System") - in `SettingsViewModel.swift`
  - `currency` (String: e.g. "USD") - in `SettingsViewModel.swift`
  - `currencySymbol` (String: e.g. "$") - in `SettingsViewModel.swift`

**File Storage:**
- Local filesystem only
- No file read/write operations in current codebase
- No document directory usage

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- None. No authentication is implemented.
- Single-user local app with no login flow.
- No biometric authentication (explicitly out of scope per `CLAUDE.md`).

## Monitoring & Observability

**Error Tracking:**
- None. No Crashlytics, Sentry, or similar service.

**Logs:**
- No logging framework. No `print()` or `os.log` calls found in production code.
- Debugging relies entirely on Xcode debugger and SwiftUI previews.

**Analytics:**
- None. No analytics SDK or tracking.

## CI/CD & Deployment

**Hosting:**
- Not applicable (iOS native app)
- No App Store Connect configuration detected
- No distribution certificates or provisioning profiles in repository

**CI Pipeline:**
- None. No GitHub Actions, Fastlane, or other CI/CD configuration.
- `.gitignore` includes fastlane patterns but no `fastlane/` directory exists.
- Build and test are run manually via Xcode or `xcodebuild` CLI.

## Environment Configuration

**Required env vars:**
- None. No environment variables used.

**Secrets location:**
- No secrets in the repository.
- `.gitignore` excludes `.env`, `.pem`, `.p12`, `.key`, `secrets/`, `Credentials/`, and `GoogleService-Info.plist`.

## Webhooks & Callbacks

**Incoming:**
- None. The app does not receive push notifications despite `remote-notification` being listed in `Info.plist` `UIBackgroundModes`. This appears to be a placeholder or leftover configuration.

**Outgoing:**
- None. No outbound HTTP requests or API calls.

## Internal Event System

**Notification Center:**
The app uses `NotificationCenter` as an internal event bus for reactive updates between layers. Defined in `ExpenseTrackerApp/Utils/Constants.swift`:

| Notification Name | Trigger Location | Subscribers |
|---|---|---|
| `transactionAdded` | `DataService.addTransaction()` | `DashboardViewModel`, `TransactionViewModel` |
| `transactionUpdated` | `DataService.updateTransaction()` | `DashboardViewModel`, `TransactionViewModel` |
| `transactionDeleted` | `DataService.deleteTransaction()` | `DashboardViewModel`, `TransactionViewModel` |

View models subscribe via Combine publishers:
```swift
NotificationCenter.default.publisher(for: .transactionAdded)
    .receive(on: DispatchQueue.main)
    .sink { [weak self] _ in self?.refreshData() }
    .store(in: &cancellables)
```

## Currency Support

**Available Currencies (Static List):**
Defined in `SettingsViewModel.swift` as a hardcoded array of 12 currencies:
- USD, EUR, GBP, JPY, CAD, AUD, INR, CNY, CHF, MXN, SGD, HKD

**No exchange rate API.** Currency selection changes the display symbol only. No currency conversion is performed.

## Integration Readiness

The codebase is structured for easy integration addition:

1. **Models are `Codable`** - Ready for JSON serialization to any API
2. **DataService is a singleton** - Single point to add network calls for persistence
3. **No network layer exists** - Would need to be built from scratch (no URLSession wrappers, no HTTP client abstraction)
4. **Combine already in use** - Natural fit for async network calls via `Future`/`AnyPublisher`
5. **`@AppStorage` for settings** - Already persists user preferences; pattern could extend to other lightweight data

---

*Integration audit: 2026-04-05*

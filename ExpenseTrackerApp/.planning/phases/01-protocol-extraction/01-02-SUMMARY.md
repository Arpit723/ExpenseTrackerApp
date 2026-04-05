---
phase: 01-protocol-extraction
plan: 02
subsystem: testing
tags: [xctest, mocking, protocol-conformance, di]

# Dependency graph
requires:
  - phase: 01-protocol-extraction/01
    provides: "DataServiceProtocol, AuthServiceProtocol, protocol-based DI in ViewModels"
provides:
  - "MockDataService conforming to DataServiceProtocol for unit testing"
  - "MockAuthService conforming to AuthServiceProtocol with configurable failure"
  - "ProtocolSmokeTests verifying mock protocol conformance (11 tests)"
affects: [phase-5-testing, auth-ui]

# Tech tracking
tech-stack:
  added: []
  patterns: [test-mock-pattern, configurable-mock-failure]

key-files:
  created:
    - "ExpenseTrackerApp/ExpenseTrackerAppTests/Mocks/MockDataService.swift"
    - "ExpenseTrackerApp/ExpenseTrackerAppTests/Mocks/MockAuthService.swift"
    - "ExpenseTrackerApp/ExpenseTrackerAppTests/ProtocolSmokeTests.swift"
  modified:
    - "ExpenseTrackerApp/ExpenseTrackerApp/Protocols/AuthServiceProtocol.swift"

key-decisions:
  - "Disambiguate Category type with ExpenseTrackerApp.Category prefix in test target (ObjC runtime collision)"
  - "Add Equatable conformance to AuthState enum for test assertions"
  - "Use mock's own categories for lookup tests (defaultCategories generates new UUIDs per call)"

patterns-established:
  - "Mock pattern: @MainActor ObservableObject with @Published properties conforming to protocol"
  - "Configurable mock: shouldFail/delay properties for testing error paths and async behavior"
  - "ExpenseTrackerApp.Type prefix required in test target for types colliding with ObjC runtime symbols"

requirements-completed: [ARCH-04]

# Metrics
duration: 47min
completed: 2026-04-05
---

# Phase 1 Plan 2: Mock Services Summary

**MockDataService and MockAuthService with configurable behavior, 11 passing protocol smoke tests enabling ViewModel unit testing without Firebase**

## Performance

- **Duration:** 47 min
- **Started:** 2026-04-05T15:41:55Z
- **Completed:** 2026-04-05T16:29:06Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- MockDataService with full DataServiceProtocol conformance (CRUD, computed totals, grouping)
- MockAuthService with configurable shouldFail/delay for testing success and error auth flows
- 11 protocol smoke tests all passing, verifying mock-ViewModel integration
- Build and full test suite pass with zero failures

## Task Commits

Each task was committed atomically:

1. **Task 1: Create MockDataService conforming to DataServiceProtocol** - `e047a0c` (feat)
2. **Task 2: Create MockAuthService and protocol conformance smoke tests** - `0664ee9` (test)

## Files Created/Modified
- `ExpenseTrackerApp/ExpenseTrackerAppTests/Mocks/MockDataService.swift` - Mock conforming to DataServiceProtocol with in-memory storage and computed properties
- `ExpenseTrackerApp/ExpenseTrackerAppTests/Mocks/MockAuthService.swift` - Mock conforming to AuthServiceProtocol with configurable failure and delay
- `ExpenseTrackerApp/ExpenseTrackerAppTests/ProtocolSmokeTests.swift` - 11 XCTest unit tests verifying both mocks work with protocol-typed ViewModels
- `ExpenseTrackerApp/ExpenseTrackerApp/Protocols/AuthServiceProtocol.swift` - Added Equatable conformance to AuthState enum

## Decisions Made
- Used `ExpenseTrackerApp.Category` prefix in test target to disambiguate from ObjC runtime's `Category` typedef -- this is a systemic issue for any test file importing both Foundation and the app module
- Added `Equatable` conformance to `AuthState` -- required for `XCTAssertEqual` in tests and `UserProfile` already conforms to `Equatable`, so no synthetic conformance needed
- Used mock's own categories for lookup test instead of creating fresh `Category.defaultCategories` -- because the static property generates new UUIDs on each access, the IDs would never match

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Category type ambiguity in test target**
- **Found during:** Task 2 (running ProtocolSmokeTests)
- **Issue:** `Category` type in test target is ambiguous between `ExpenseTrackerApp.Category` and Objective-C `objc_category` from `objc/runtime.h`, which is transitively imported via Foundation
- **Fix:** Qualified all `Category` references as `ExpenseTrackerApp.Category` in MockDataService.swift and ProtocolSmokeTests.swift
- **Files modified:** MockDataService.swift, ProtocolSmokeTests.swift
- **Verification:** Build and all 11 tests pass
- **Committed in:** e047a0c (Task 1, retroactively included in Task 2 commit)

**2. [Rule 1 - Bug] Added Equatable conformance to AuthState enum**
- **Found during:** Task 2 (running ProtocolSmokeTests)
- **Issue:** `XCTAssertEqual` requires `Equatable` conformance but `AuthState` enum did not declare it
- **Fix:** Changed `enum AuthState` to `enum AuthState: Equatable` in AuthServiceProtocol.swift
- **Files modified:** AuthServiceProtocol.swift
- **Verification:** All tests pass, including `testMockAuthServiceInitialState` and `testMockAuthServiceStateListener`
- **Committed in:** 0664ee9 (Task 2 commit)

**3. [Rule 1 - Bug] Fixed testMockDataServiceCategoryLookup using wrong category source**
- **Found during:** Task 2 (running ProtocolSmokeTests)
- **Issue:** `Category.defaultCategories` is a computed property generating new UUIDs each call, so test's `Category.defaultCategories[0].id` differs from MockDataService's internally-initialized categories
- **Fix:** Changed test to use `mockDataService.categories[0]` instead of `Category.defaultCategories[0]`
- **Files modified:** ProtocolSmokeTests.swift
- **Verification:** testMockDataServiceCategoryLookup now passes
- **Committed in:** 0664ee9 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs)
**Impact on plan:** All fixes necessary for correctness. The Category disambiguation is a systemic pattern that will apply to all future test files. The AuthState Equatable conformance is a natural requirement for testability. No scope creep.

## Issues Encountered
- `Category` name collision with ObjC runtime is a known Swift/ObjC interop issue when `@testable import` brings both Foundation and app module types into scope. The `ExpenseTrackerApp.` prefix is the standard fix.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Both mock services ready for ViewModel unit testing in Phase 5
- MockAuthService's `shouldFail` flag enables testing auth error flows
- MockDataService enables DashboardViewModel, TransactionViewModel, and SettingsViewModel testing
- Category disambiguation pattern established for all future test files

---
*Phase: 01-protocol-extraction*
*Completed: 2026-04-05*

## Self-Check: PASSED
- All 4 created/modified files verified present
- Both task commits (e047a0c, 0664ee9) verified in git log
- Build exits 0, all 11 smoke tests + 2 existing tests pass

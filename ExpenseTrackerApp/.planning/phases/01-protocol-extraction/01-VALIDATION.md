---
phase: 1
slug: protocol-extraction
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-05
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | XCTest (Apple built-in) |
| **Config file** | None — test targets configured in project.pbxproj |
| **Quick run command** | `xcodebuild build -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'` |
| **Full suite command** | `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild build -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16'`
- **After every plan wave:** Run `xcodebuild test -scheme ExpenseTrackerApp -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:ExpenseTrackerAppTests`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | ARCH-01, ARCH-02 | — | N/A | compile | `xcodebuild build ...` | N/A | ⬜ pending |
| 1-01-02 | 01 | 1 | ARCH-03 | — | N/A | compile | `xcodebuild build ...` | N/A | ⬜ pending |
| 1-02-01 | 02 | 2 | ARCH-04 | — | N/A | compile | `xcodebuild build ...` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 2 | ARCH-04 | — | N/A | unit | `xcodebuild test ... -only-testing:ExpenseTrackerAppTests` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `ExpenseTrackerAppTests/Mocks/MockDataService.swift` — mock implementation
- [ ] `ExpenseTrackerAppTests/Mocks/MockAuthService.swift` — mock implementation
- [ ] Both files added to `ExpenseTrackerAppTests` target in `project.pbxproj`
- [ ] `ExpenseTrackerAppTests/ProtocolSmokeTests.swift` — unit tests verifying mocks work with ViewModels (unit tests only, no UI tests)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| App runs identically after refactoring | All | Visual verification requires launching app | Build & run in simulator, verify Dashboard and Transactions tabs work as before |

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending

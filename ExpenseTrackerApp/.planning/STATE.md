# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-05)

**Core value:** Users can securely log in, have their transactions persisted across sessions, and trust the app works correctly through automated tests.
**Current focus:** Phase 1 — Protocol Extraction

## Current Position

Phase: 1 of 5 (Protocol Extraction)
Plan: 0 of 2 in current phase
Status: Ready to plan
Last activity: 2026-04-05 — Roadmap created

Progress: [..........] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 0
- Average duration: -
- Total execution time: 0 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| - | - | - | - |

**Recent Trend:**
- Last 5 plans: -
- Trend: -

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Protocol extraction before Firebase SDK (prevents hard coupling, enables 80% coverage)
- Auth UI built with mock service (testable without Firebase console setup)
- One-time Firestore fetches for v1, not real-time listeners (simpler, lower cost)
- Categories remain client-side hardcoded (not a Firestore subcollection)
- Three-state auth model (loading/authenticated/unauthenticated) prevents login screen flash

### Pending Todos

None yet.

### Blockers/Concerns

- GoogleService-Info.plist must be excluded from git but present in Xcode project (Phase 3)
- UUID encoding in Firestore needs a round-trip validation test (Phase 4)
- Settings (currency/theme) remain device-local via UserDefaults, not user-scoped to Firestore (accepted for v1)

## Session Continuity

Last session: 2026-04-05
Stopped at: Roadmap created, ready for Phase 1 planning
Resume file: None

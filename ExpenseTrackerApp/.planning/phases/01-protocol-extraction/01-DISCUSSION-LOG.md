# Phase 1: Protocol Extraction - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-05
**Phase:** 01-protocol-extraction
**Areas discussed:** Protocol Design

---

## Protocol Design

| Option | Description | Selected |
|--------|-------------|----------|
| One per service (DataServiceProtocol + AuthServiceProtocol) | Simple, matches current DataService structure | ✓ |
| Interface segregation | Split DataServiceProtocol into Readable/Writable/Queryable | |
| Split read/write + reactivity | Separate protocol for reactivity concerns | |

**User's choice:** One per service (Recommended)
**Notes:** User selected "One per service" for simplicity — matches existing DataService structure and keeps refactoring minimal

---

## Areas at Claude's Discretion

- Protocol file organization
- Mock sophistication level (stubs vs configurable)
- Reactivity bridging approach (protocol getters vs @Published requirement)
- Notification handling (keep in concrete implementation)
- Whether to use `any Protocol` or `some Protocol` syntax

---

## Deferred Ideas

None — discussion stayed within phase scope

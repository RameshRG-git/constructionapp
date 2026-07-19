# Roadmap

This roadmap follows the existing implementation sequence for the construction management feature.

## Phase 1: Foundation

- Finalize backend app factory, database wiring, and configuration.
- Establish shared API response and error handling.
- Implement authentication and role authorization guards.
- Set up frontend shell, routing, and shared layout.

## Phase 2: MVP - Site Oversight

- Deliver site CRUD, status updates, search, and closure flows.
- Add site summary endpoint and dashboard view.
- Validate independent usability for site managers.

## Phase 3: Inventory Control

- Deliver inventory item management and stock adjustments.
- Add low-stock flags and shortage visibility in summaries.
- Validate independent usability for site and warehouse teams.

## Phase 4: Workload and Budget Tracking

- Deliver work assignment creation and workload summaries.
- Deliver budget records, variance calculations, and over-budget indicators.
- Integrate reporting charts in dashboard flows.

## Phase 5: Polish and Hardening

- Improve logging, traceability, and operational error messages.
- Tighten authorization checks across all mutation endpoints.
- Finalize responsive behavior and UX polish.
- Verify CI coverage for backend and frontend checks.

## Delivery Strategy

- Ship in incremental slices aligned with user stories.
- Keep each phase independently testable before advancing.
- Preserve backward compatibility of API payloads during iteration.

## Near-Term Milestones

- M1: Foundation complete and stable in CI.
- M2: Site Oversight production-ready (MVP checkpoint).
- M3: Inventory workflows production-ready.
- M4: Workload and budget workflows production-ready.
- M5: Cross-cutting polish complete and release candidate prepared.

# Roadmap

This roadmap follows the existing implementation sequence for the construction management feature.

## Current Status

- Phases 1 through 5 are delivered.
- Post-MVP tenant/team/workload-budget enhancements are delivered and in active use.
- Expense-based budgeting, user provisioning, and authenticated access are delivered.

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
- Extend workloads with day/date-range tracking and historical filtering.
- Deliver budget records, payroll-aware summary calculations, and over-budget indicators.

## Phase 5: Team Management and Tenant Operations

- Deliver Team Management page with member registry.
- Deliver role/day-rate catalog with tenant defaults.
- Deliver tenant administration and tenant-aware request routing.

## Phase 6: CRUD Completion and UX Simplification

- Add delete actions for workload, inventory, and budget records.
- Simplify global navigation and workspace controls.
- Keep global inventory and site inventory usage intentionally distinct.

## Phase 7: Expense-Based Budgeting

- Capture unit cost on materials and derive materials value.
- Treat workload payments and materials value as budget expenses.
- Present remaining budget against total expense and simplify budget controls.

## Phase 8: Authentication and Access Control

- Provision application users and map them to tenants with access roles.
- Deliver sign-in with server-side sessions and automatic tenant activation.
- Restrict tenant administration to the `tenant_admin` role.

## Phase 9: Polish and Hardening

- Improve logging, traceability, and operational error messages.
- Tighten authorization checks across all mutation endpoints.
- Finalize responsive behavior and UX polish.
- Verify CI coverage for backend and frontend checks.

## Phase 10: Weekly Payroll Controls (Delivered)

- Add a site Payments tab for Sunday-to-Saturday payroll derived from workloads.
- Exclude employee sick-leave dates from workload pay and hours.
- Add Team Payroll controls for sick-leave ranges and employee salary advances.
- Recover due advances FIFO from net weekly pay and carry unpaid balances forward.
- Preserve an advance-recovery ledger to prevent duplicate deductions.
- Add budget transaction type, comments, and editable transaction date.

## Phase 11: Relational Integrity, Half-Day Workloads, and Misc Expense (Delivered)

- Relate work assignments, sick leave, advances, recoveries, and payroll payments to a team member
  by ID so renaming a member no longer disconnects historical records.
- Support half-day workloads (proportional pay and hours) for single-day entries.
- Add a budget entry type (allocation or expense) so miscellaneous site costs are tracked alongside
  budget allocations and reflected in total expense and remaining budget.

## Delivery Strategy

- Ship in incremental slices aligned with user stories.
- Keep each phase independently testable before advancing.
- Preserve backward compatibility of API payloads during iteration.

## Near-Term Milestones

- M1: Foundation complete and stable in CI.
- M2: Site Oversight production-ready (MVP checkpoint).
- M3: Inventory workflows production-ready.
- M4: Workload and budget workflows production-ready.
- M5: Team and tenant operations production-ready.
- M6: Delete and UX simplification complete.
- M7: Expense-based budgeting adopted for site reporting.
- M8: Authenticated, role-aware access enforced across the product.
- M9: Cross-cutting polish complete and release candidate prepared.
- M10: Weekly payroll, sick-leave, advance recovery, and budget transaction metadata delivered.

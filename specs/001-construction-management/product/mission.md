# Mission

Build a browser-first, tenant-aware construction management application that helps teams run sites with clear operational visibility across site status, inventory, workloads, budgets, and team capacity.

## Purpose

Enable site managers, site operations, warehouse staff, and finance reviewers to coordinate daily construction work with shared, reliable data.

## Product Goals

- Track construction sites from planning to closure.
- Keep materials levels accurate and highlight low-stock risks early.
- Balance team workload with day/date-range assignment visibility.
- Monitor budget health by treating workload payments and materials value as expenses.
- Standardize labor planning with tenant-specific role/day-rate catalogs.
- Give each user secure, role-appropriate access to their own tenant workspace.
- Provide a unified site summary for faster, better decisions.

## Scope (MVP)

- Site CRUD, status updates, search, and closure.
- Tenant-aware materials tracking with unit cost, stock adjustments, and list filters.
- Work assignment tracking with day/date-range support and history search.
- Budget records with workload expense, materials value, total expense, and remaining budget.
- Team member management and role/day-rate catalog management.
- Delete actions for workload, materials, and budget records.
- Authenticated sign-in, user provisioning, and user-to-tenant mapping.
- Role-based access control and server-side validation.

## Success Signals

- Users can create and update sites quickly in normal operations.
- Low-stock and budget pressure conditions are visible without manual calculations.
- Signed-in users land in the correct tenant without manual switching.
- Core end-to-end workflows can be completed in one session.
- Typical API summary and CRUD operations remain responsive for active teams.

## Non-Goals (Initial Release)

- Native mobile apps.
- Advanced forecasting and optimization.
- Procurement automation or deep accounting integrations.
- Full payroll processing and disbursement workflows.
- Self-service registration, password reset, and multi-factor authentication.

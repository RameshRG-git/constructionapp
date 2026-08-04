# Research: Construction Management Application

## Decision 1: Backend Framework
- Decision: Use Flask for the backend API with SQLAlchemy-style data access and migration support.
- Rationale: Flask is lightweight, explicit, and a good fit for a focused CRUD-heavy operations app
  that needs clear business rules and a small surface area.
- Alternatives considered: FastAPI, Django.

## Decision 2: Frontend Framework
- Decision: Use Flutter for the browser client.
- Rationale: The user explicitly requested Flutter, and Flutter web supports a shared UI layer for the
  site management, inventory, workload, and budget flows.
- Alternatives considered: React, Vue, native mobile apps.

## Decision 3: Charting Approach
- Decision: Keep reporting focused on API-driven summary cards and list-based insights in the current
  release.
- Rationale: The operational workflows prioritized site, inventory, workload, budget, and team actions;
  chart integrations can be added later without changing core domain contracts.
- Alternatives considered: Chart.js integration, Flutter chart packages.

## Decision 4: Persistence Model
- Decision: Use PostgreSQL as the single system of record.
- Rationale: The problem is relational by nature, with sites, inventory, assignments, and budgets
  sharing transactional relationships and reporting needs.
- Alternatives considered: SQLite, NoSQL document storage.

## Decision 5: Authentication and Access Control
- Decision: Assume authenticated browser users with role-based authorization enforced in the backend,
  using secure browser-friendly session handling.
- Rationale: The feature requires role-based access, and server-side enforcement keeps mutating actions
  protected without exposing credentials in the browser.
- Alternatives considered: Local token storage, unauthenticated access.

## Decision 6: Tenant Isolation Strategy
- Decision: Use tenant-aware row isolation via `tenant_name` on domain models, resolved from `X-Tenant`
  request header with a default fallback tenant.
- Rationale: This keeps the architecture simple while providing practical multi-tenant separation and
  tenant-switch capability.
- Alternatives considered: single-tenant-only design, schema-per-tenant-only runtime routing.

## Decision 7: Team and Payroll Input Model
- Decision: Introduce a tenant-managed team member registry plus a role/day-rate catalog, then compute
  assignment payroll from selected role and assignment period length.
- Rationale: Users requested role standardization and budget deduction visibility tied to workload entry.
- Alternatives considered: free-text-only assignees without role rates, external payroll integration.

## Decision 8: Testing Strategy
- Decision: Use PyTest for backend coverage and Flutter tests for browser flows.
- Rationale: This gives direct coverage over the critical CRUD and reporting paths while keeping the
  validation stack aligned with the requested technology choices.
- Alternatives considered: End-to-end-only testing, backend-only testing.

## Decision 9: Deployment and Operations
- Decision: Standardize operational runbook steps around Alembic migrations, systemd backend restart,
  Flutter web release build, and rsync-based static deploy.
- Rationale: This matches the deployed environment and reduced repeated migration/runtime drift issues.
- Alternatives considered: ad hoc process kills/manual static copies.

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
- Decision: Use Chart.js for reporting views and feed it with API aggregation endpoints.
- Rationale: The user requested Chart.js, and browser-based charts are a good fit for dashboard-style
  summaries such as budget variance and inventory risk.
- Alternatives considered: Flutter-only chart packages, server-rendered charts.

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

## Decision 6: Testing Strategy
- Decision: Use PyTest for backend coverage and Flutter tests for browser flows.
- Rationale: This gives direct coverage over the critical CRUD and reporting paths while keeping the
  validation stack aligned with the requested technology choices.
- Alternatives considered: End-to-end-only testing, backend-only testing.

## Decision 7: CI/CD
- Decision: Use GitLab CI to run backend tests, frontend tests, and build checks.
- Rationale: The user specified GitLab CI, and a staged pipeline keeps the app shippable with minimal
  process overhead.
- Alternatives considered: GitHub Actions, ad hoc local checks.

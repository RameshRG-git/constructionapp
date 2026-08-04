# Tech Stack

## Architecture

- Two-tier web architecture.
- Backend API: Flask service layer with domain rules and authorization.
- Frontend client: Flutter Web application for browser-first delivery.
- Database: PostgreSQL for transactional persistence.
- Tenant isolation: request-scoped tenant context via `X-Tenant` + default tenant fallback.

## Backend

- Language: Python 3.11
- Framework: Flask
- ORM and Migrations: Flask-SQLAlchemy, Flask-Migrate
- Database Driver: psycopg
- Testing: PyTest

## Frontend

- Language: Dart
- Framework: Flutter 3.x (Web target)
- HTTP Integration: `http` package
- UI System: Material 3
- Testing: Flutter widget and integration tests

## Data and Domain

- Core domains: Tenants, Sites, Inventory, Workloads, Budgets, Team Members, Team Role Rates.
- Server-side validation for mutating operations.
- Role-based access control enforced in backend services and APIs.
- Tenant-scoped CRUD and summary queries.

## DevOps and Quality

- CI/CD: repository checks for backend and frontend validation before deployment.
- Logging and tracing hooks in backend extensions for operational diagnostics.
- Contract-driven API design using specs and endpoint documentation.

## Runtime Targets

- Primary target: Modern desktop and mobile browsers.
- Deployment scope: Multi-tenant operation with tenant-scoped data separation.
- Performance expectation: Typical CRUD and summary responses under 2 seconds in active usage.

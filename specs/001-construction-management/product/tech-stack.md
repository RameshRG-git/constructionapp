# Tech Stack

## Architecture

- Two-tier web architecture.
- Backend API: Flask service layer with domain rules and authorization.
- Frontend client: Flutter Web application for browser-first delivery.
- Database: PostgreSQL for transactional persistence.

## Backend

- Language: Python 3.11
- Framework: Flask
- ORM and Migrations: Flask-SQLAlchemy, Flask-Migrate
- Database Driver: psycopg
- Testing: PyTest

## Frontend

- Language: Dart
- Framework: Flutter 3.x (Web target)
- HTTP Integration: Flutter HTTP client packages
- Charts and Reporting: Chart.js browser integration
- Testing: Flutter widget and integration tests

## Data and Domain

- Core domains: Sites, Inventory, Workloads, Budgets, Roles.
- Server-side validation for mutating operations.
- Role-based access control enforced in backend services and APIs.

## DevOps and Quality

- CI/CD: GitLab CI pipeline for backend checks, frontend checks, and build validation.
- Logging and tracing hooks in backend extensions for operational diagnostics.
- Contract-driven API design using specs and endpoint documentation.

## Runtime Targets

- Primary target: Modern desktop and mobile browsers.
- Deployment scope: Single organization instance.
- Performance expectation: Typical CRUD and summary responses under 2 seconds in active usage.

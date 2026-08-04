# Implementation Plan: Construction Management Application

**Branch**: `001-construction-management` | **Date**: 2026-05-18 | **Spec**: [spec.md](spec.md)

**Last Updated**: 2026-07-31

**Input**: Feature specification from `/specs/001-construction-management/spec.md`

**Note**: This plan follows the spec-kit workflow for the construction management feature.

## Summary

Build a browser-based construction operations system with a Flask backend and a Flutter web
frontend. The delivered scope now includes tenant-aware data isolation, site tracking, global and
site inventory views, workload period tracking (day/date-range), budget monitoring with payroll
impact, team management, and role/day-rate catalog management. Use PostgreSQL for persistence,
PyTest for backend verification, and Flutter analyze/test for frontend quality checks.

## Technical Context

**Language/Version**: Python 3.11 for backend, Dart/Flutter 3.x for frontend

**Primary Dependencies**: Flask, Flask-SQLAlchemy, Flask-Migrate, psycopg, PyTest, Flutter SDK,
HTTP package

**Storage**: PostgreSQL

**Testing**: PyTest for backend unit/integration coverage; Flutter analyze and widget/integration
tests for frontend flows; smoke checks for tenant/site/inventory/workload/budget/team flows

**Target Platform**: Web browser on desktop and mobile devices

**Site Type**: Web application with separate backend API and frontend client

**Performance Goals**: Typical CRUD and summary responses should remain under 2 seconds for an
active site workspace; dashboard charts should render without blocking core workflows

**Constraints**: Browser-first delivery, role-based access control, secure server-side validation,
and a simple two-tier architecture aligned with the constitution

**Scale/Scope**: Multi-tenant deployment with tenant-scoped sites, inventory, workloads, budgets,
and team data

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

The constitution is satisfied:

- Browser-first delivery is preserved through the Flutter web client.
- The stack remains simple: one Flask API, one Flutter frontend, one PostgreSQL database.
- Critical paths are covered by PyTest and Flutter tests.
- Server-side validation and role-based access are planned for all mutating actions.
- Logging, readable structure, and explicit API contracts support maintainability.
- Tenant-scoped data access is enforced via request tenant resolution and model-level tenant fields.

## Site Structure

### Documentation (this feature)

```text
specs/001-construction-management/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── http-api.md
└── tasks.md
```

### Source Code (repository root)

```text
backend/
├── app/
│   ├── api/
│   ├── models/
│   ├── services/
│   └── extensions/
└── tests/
    ├── unit/
    └── integration/

frontend/
├── lib/
│   ├── app/
│   ├── features/
│   │   ├── dashboard/
│   │   ├── sites/
│   │   ├── inventory/
│   │   ├── workloads/
│   │   └── budgets/
│   └── shared/
├── test/
└── web/

.gitlab-ci.yml
```

**Structure Decision**: Use a two-tier web architecture with Flask handling data, security, and
business rules, and Flutter handling the browser UI, navigation, and operational workflows.

## Complexity Tracking

No constitution violations require justification for this feature.

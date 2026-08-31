# Tasks: Construction Management Application

**Input**: Design documents from `/specs/001-construction-management/`

**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Test tasks are not included because they were not explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Site initialization and basic structure

- [x] T001 Create the backend application package structure in backend/app/, backend/app/api/, backend/app/models/, backend/app/services/, and backend/app/extensions/
- [x] T002 Create the Flutter frontend package structure in frontend/lib/app/, frontend/lib/features/, frontend/lib/shared/, and frontend/web/
- [x] T003 [P] Add the GitLab CI pipeline file at .gitlab-ci.yml for backend, frontend, and database validation jobs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Initialize Flask application configuration, app factory, and extension wiring in backend/app/__init__.py and backend/app/extensions/__init__.py
- [x] T005 [P] Create PostgreSQL connection, migration, and environment configuration helpers in backend/app/extensions/database.py and backend/app/config.py
- [x] T006 [P] Create shared API error handling and response helpers in backend/app/api/errors.py and backend/app/api/response.py
- [x] T007 Define base authentication and role-based authorization guards in backend/app/services/auth.py
- [x] T008 Define shared domain enums and validation utilities for statuses, roles, and money fields in backend/app/services/domain_rules.py
- [x] T009 Establish the Flutter app shell, routing entry point, and shared layout in frontend/lib/app/main.dart and frontend/lib/app/router.dart

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Site Oversight (Priority: P1) 🎯 MVP

**Goal**: Let site managers create, view, update, search, and close construction sites with a combined site summary.

**Independent Test**: A manager can create a site, update its status or dates, open the site summary, and see the saved changes reflected immediately.

### Implementation for User Story 1

- [x] T010 [P] [US1] Create the Site model and status rules in backend/app/models/site.py
- [x] T011 [P] [US1] Create the site repository and service layer in backend/app/services/site_service.py
- [x] T012 [US1] Implement site CRUD and close endpoints in backend/app/api/sites.py
- [x] T013 [US1] Implement the site summary aggregation endpoint in backend/app/api/site_summary.py
- [x] T014 [P] [US1] Build the Flutter site list and site detail screens in frontend/lib/features/sites/
- [x] T015 [US1] Build the Flutter site summary dashboard view in frontend/lib/features/dashboard/
- [x] T016 [US1] Wire the site screens to the API client in frontend/lib/features/sites/site_api.dart and frontend/lib/features/dashboard/dashboard_api.dart
- [x] T017 [US1] Add site search and status filtering support in backend/app/api/sites.py and frontend/lib/features/sites/

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Inventory Control (Priority: P2)

**Goal**: Let site and warehouse users track inventory items, adjust stock, and identify low-stock materials.

**Independent Test**: A user can add an inventory item, post received or issued stock changes, and view low-stock warnings in the site inventory view.

### Implementation for User Story 2

- [x] T018 [P] [US2] Create the InventoryItem and InventoryTransaction models in backend/app/models/inventory.py
- [x] T019 [P] [US2] Create the inventory service layer and stock adjustment rules in backend/app/services/inventory_service.py
- [x] T020 [US2] Implement inventory item and transaction endpoints in backend/app/api/inventory.py
- [x] T021 [US2] Extend the site summary aggregation to include low-stock counts and shortage amounts in backend/app/api/site_summary.py
- [x] T022 [P] [US2] Build the Flutter inventory screens for item list, item detail, and stock adjustment in frontend/lib/features/inventory/
- [x] T023 [US2] Add inventory low-stock indicators and summary cards in frontend/lib/features/dashboard/
- [x] T024 [US2] Wire the inventory screens to the API client in frontend/lib/features/inventory/inventory_api.dart

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Workload and Budget Tracking (Priority: P3)

**Goal**: Let site coordinators assign work, view team workload, and track budget performance against plan.

**Independent Test**: A coordinator can create an assignment, review workload distribution, update a budget record, and see the resulting budget variance in the site summary.

### Implementation for User Story 3

- [x] T025 [P] [US3] Create the WorkAssignment model and status rules in backend/app/models/work_assignment.py
- [x] T026 [P] [US3] Create the BudgetRecord model and variance rules in backend/app/models/budget_record.py
- [x] T027 [P] [US3] Create the workload and budget service layers in backend/app/services/workload_service.py and backend/app/services/budget_service.py
- [x] T028 [US3] Implement workload assignment endpoints in backend/app/api/workloads.py
- [x] T029 [US3] Implement budget tracking endpoints in backend/app/api/budgets.py
- [x] T030 [US3] Extend the site summary aggregation to include workload and budget metrics in backend/app/api/site_summary.py
- [x] T031 [P] [US3] Build the Flutter workload screens in frontend/lib/features/workloads/
- [x] T032 [P] [US3] Build the Flutter budget screens and reporting charts in frontend/lib/features/budgets/
- [x] T033 [US3] Integrate summary reporting views with aggregated API data in frontend/lib/features/dashboard/
- [x] T034 [US3] Wire workload and budget screens to the API client in frontend/lib/features/workloads/workload_api.dart and frontend/lib/features/budgets/budget_api.dart

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T035 [P] Add shared backend logging, audit-friendly error messages, and request tracing in backend/app/extensions/logging.py
- [x] T036 [P] Finalize Flutter shared widgets, navigation polish, and responsive layout behavior in frontend/lib/shared/
- [x] T037 Review and tighten authorization checks across backend/app/api/ and backend/app/services/
- [x] T038 Validate quickstart steps against the implemented stack in specs/001-construction-management/quickstart.md
- [x] T039 Confirm the GitLab CI pipeline covers backend tests, frontend tests, and build checks in .gitlab-ci.yml

---

## Phase 7: Post-MVP Enhancements (Delivered)

**Purpose**: Add tenant-first workflows, team operations, workload period controls, and final CRUD completeness.

- [x] T040 Add tenant model, tenant APIs, and request-tenant resolution in backend/app/models/tenant.py, backend/app/api/tenants.py, and backend/app/services/tenancy.py
- [x] T041 Seed and enforce default tenant behavior (`kaniskahomes`) across backend and frontend API client context
- [x] T042 Rename project domain artifacts to site domain artifacts across API, models, and frontend routes/screens
- [x] T043 Add global tenant-wide inventory listing with optional site filter in backend/app/api/inventory.py and frontend/lib/features/inventory/inventory_screen.dart
- [x] T044 Add site-scoped inventory workspace screen in frontend/lib/features/inventory/site_inventory_screen.dart
- [x] T045 Introduce team member model/service/API in backend/app/models/team_member.py, backend/app/services/team_member_service.py, backend/app/api/team_members.py
- [x] T046 Introduce team role/day-rate model/API with tenant default role seeding in backend/app/models/team_role_rate.py and backend/app/api/team_roles.py
- [x] T047 Add Team Management UI with members and role catalog tabs in frontend/lib/features/team/team_management_screen.dart and route wiring
- [x] T048 Extend workloads to support period start/end dates, auto-complete past workloads, and history filters in backend/app/models/work_assignment.py and backend/app/api/workloads.py
- [x] T049 Update workload UI for day vs date-range entry, role-based pay projection, and current-only default listing in frontend/lib/features/workloads/workloads_screen.dart
- [x] T050 Extend budget summary with payroll totals and remaining budget calculation in backend/app/api/budgets.py and frontend/lib/features/budgets/budgets_screen.dart
- [x] T051 Add delete endpoints for assignments, inventory items, and budget records in backend/app/api/workloads.py, backend/app/api/inventory.py, and backend/app/api/budgets.py
- [x] T052 Add delete actions with confirmation dialogs in frontend/lib/features/workloads/workloads_screen.dart, frontend/lib/features/inventory/inventory_screen.dart, frontend/lib/features/inventory/site_inventory_screen.dart, and frontend/lib/features/budgets/budgets_screen.dart

---

## Phase 8: Expense Model, Access Control, and Sign-In (Delivered)

**Purpose**: Treat operational activity as budget expense and secure the application behind authenticated, role-aware access.

- [x] T053 Add `unit_cost` to inventory items and expose derived `inventory_value` in backend/app/models/inventory.py and backend/app/api/inventory.py
- [x] T054 Capture and display unit cost in frontend/lib/features/inventory/inventory_screen.dart and frontend/lib/features/inventory/site_inventory_screen.dart
- [x] T055 Treat workload payments and materials value as expenses in backend/app/api/budgets.py with total_expense and remaining_budget outputs
- [x] T056 Simplify budget UI by removing planned amount, status chips, and variance chip in frontend/lib/features/budgets/budgets_screen.dart
- [x] T057 Default workload filtering to Open, remove Blocked, and include completed records under All in backend/app/api/workloads.py and frontend/lib/features/workloads/workloads_screen.dart
- [x] T058 Rename inventory experience to Materials Hub and Site Materials across navigation, routes, and screens
- [x] T059 Add AppUser and UserTenant models with migration in backend/app/models/app_user.py, backend/app/models/user_tenant.py, and backend/migrations/versions/f3c8d41b9a27_add_app_users_and_user_tenants.py
- [x] T060 Add user provisioning and tenant mapping endpoints in backend/app/services/user_service.py and backend/app/api/users.py
- [x] T061 Add Users and User Mapping tabs in frontend/lib/features/tenants/tenant_admin_screen.dart with frontend/lib/features/tenants/user_api.dart
- [x] T062 Add session-based sign-in endpoints in backend/app/api/auth.py
- [x] T063 Add login screen and auth state handling in frontend/lib/features/auth/login_screen.dart, frontend/lib/features/auth/auth_api.dart, and frontend/lib/shared/auth_scope.dart
- [x] T064 Guard routes, auto-activate the mapped tenant, and gate Tenant Admin on the `tenant_admin` role in frontend/lib/shared/app_shell.dart and frontend/lib/app/main.dart

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Depends on the shared site foundation but remains independently testable
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Depends on the shared site foundation but remains independently testable

### Within Each User Story

- Models and shared rules before services
- Services before API endpoints or UI wiring
- Core implementation before dashboard/reporting integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel (if team capacity allows)
- Different user stories can be worked on in parallel by different team members
- UI and backend tasks in a story marked [P] can run in parallel where file dependencies do not overlap

---

## Parallel Example: User Story 1

```bash
# Launch backend and frontend work for User Story 1 together:
Task: "Create the Site model and status rules in backend/app/models/site.py"
Task: "Build the Flutter site list and site detail screens in frontend/lib/features/sites/"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Avoid vague tasks and same-file conflicts that break independence
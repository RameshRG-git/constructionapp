# Feature Specification: Construction Management Application

**Feature Branch**: `001-construction-management`

**Created**: 2026-05-18

**Last Updated**: 2026-08-31

**Status**: Implemented and Iterating

**Input**: User description: "build an construction application that helps to manage the construction sites, manage inventory, manage work loads, budgetting etc.,"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Site Oversight (Priority: P1)

A site manager can create and maintain construction sites with the core details needed to
track status, schedule, and ownership.

**Why this priority**: Site tracking is the central workflow that the rest of the application depends on.

**Independent Test**: Create a site, update its status, and confirm the site list reflects the
saved changes.

**Acceptance Scenarios**:

1. **Given** a manager has access to the application, **When** they create a new site with a name,
   location, and target dates, **Then** the site appears in the active site list.
2. **Given** an existing site, **When** the manager updates its status or dates, **Then** the
   updated values are visible and preserved.

---

### User Story 2 - Inventory Control (Priority: P2)

A site or warehouse user can record construction materials, view available stock, and identify items
that need replenishment.

**Why this priority**: Inventory visibility prevents delays caused by missing or exhausted materials.

**Independent Test**: Add an item, adjust its quantity, and verify the available stock count changes
accordingly.

**Acceptance Scenarios**:

1. **Given** a tracked material, **When** stock is received or used, **Then** the available quantity
   is updated.
2. **Given** an item falls below its minimum threshold, **When** the inventory is reviewed, **Then**
   the item is flagged for replenishment.

---

### User Story 3 - Workload and Budget Tracking (Priority: P3)

A site coordinator can assign work, review team workload distribution, and monitor spending
against the planned budget.

**Why this priority**: Coordinating effort and spending is needed to keep active sites on schedule
and within financial limits.

**Independent Test**: Assign work to a team member and record a budget update, then confirm both are
visible in the site summary.

**Acceptance Scenarios**:

1. **Given** a site with assigned team members, **When** work is allocated, **Then** the workload
   summary shows the assignment.
2. **Given** a site budget and actual spend, **When** spending changes, **Then** the budget view
  shows remaining, payroll impact, and over-budget amounts.

---

### User Story 4 - Team and Role Management (Priority: P2)

A tenant administrator can manage reusable role/day-rate definitions and team members so
workload planning can use standardized pay rates.

**Why this priority**: Team and pay-rate consistency is needed for reliable payroll deduction and
workload cost projection.

**Independent Test**: Add a role, add a team member with that role, and create a workload that
uses the same role to confirm paid amount calculation is consistent.

**Acceptance Scenarios**:

1. **Given** role/day-rate catalog access, **When** an admin creates or updates roles,
  **Then** those roles are available in member and workload flows.
2. **Given** a team member with a title, **When** workload is assigned by day or date range,
  **Then** projected payroll is calculated from the mapped role/day-rate.

---

### User Story 5 - Secure Sign-In and Tenant Access (Priority: P1)

A user signs in with their own credentials and lands directly in the tenant they are assigned to,
seeing only the administration features their access role permits.

**Why this priority**: Operational data must not be reachable without authentication, and tenant
context must be correct from the first screen.

**Independent Test**: Sign in as a user mapped to one tenant, confirm that tenant becomes active,
and confirm Tenant Admin is visible only for a `tenant_admin` user.

**Acceptance Scenarios**:

1. **Given** valid credentials, **When** the user signs in, **Then** the session is established and
   the mapped tenant becomes the active tenant.
2. **Given** invalid credentials, **When** sign-in is attempted, **Then** a single generic failure
   message is shown without revealing which field was wrong.
3. **Given** a signed-in user without the `tenant_admin` role, **When** they view navigation or
   request the tenant admin route directly, **Then** the feature is unavailable.

### Edge Cases

- What happens when a site is closed while inventory or workload records still reference it?
- How does the system handle negative stock, missing cost data, or budget entries that exceed the
  planned amount?
- What happens when two users update the same site or stock record close together?
- How are records isolated when two tenants use the same site names or role titles?
- What happens when users try to query only current workloads versus historical workloads?
- What happens when a user has no tenant mapping, or their only mapping is deactivated?
- What happens when a signed-in user is deactivated during an active session?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST allow users to create, view, update, and close construction sites.
- **FR-002**: The system MUST store core site details including site name, site location, owner,
  planned start date, planned end date, and status.
- **FR-003**: The system MUST use consistent site statuses of planned, active, on hold, and closed.
- **FR-004**: The system MUST isolate all operational records by tenant and resolve tenant context
  from request context with a default tenant fallback.
- **FR-005**: The system MUST allow users to record inventory items with item name, category, unit of
  measure, current quantity, and minimum stock level.
- **FR-006**: The system MUST allow users to list inventory at tenant-wide level and optionally filter
  by site.
- **FR-007**: The system MUST allow users to adjust inventory quantities when materials are received,
  issued, or corrected.
- **FR-008**: The system MUST flag inventory items that fall below their minimum stock level and show the
  shortage amount.
- **FR-009**: The system MUST allow users to assign workloads by day or date range and store the
  effective period start/end dates.
- **FR-010**: The system MUST auto-complete workloads whose period has already ended.
- **FR-011**: The system MUST support current-workload default views and searchable history views.
- **FR-012**: The system MUST allow users to record planned budget amounts and actual spending for a
  site and capture budget category.
- **FR-013**: The system MUST treat workload payments and site materials value as expenses and show
  workload expense, materials value, total expense, and remaining budget in the budget summary.
- **FR-014**: The system MUST capture a unit cost for materials and use it to calculate materials
  value as quantity multiplied by unit cost.
- **FR-014**: The system MUST include Team Management with member CRUD-lite (create/list/update)
  and role/day-rate catalog management.
- **FR-015**: The system MUST seed default role/day-rate entries for a tenant when none exist.
- **FR-016**: The system MUST support delete operations for workload records, inventory records,
  and budget records.
- **FR-017**: The system MUST preserve changes made to sites, inventory, work assignments, budget
  records, team members, and team roles.
- **FR-018**: The system MUST show clear error feedback when a requested action cannot be completed.
- **FR-019**: The system MUST provide searchable views for sites, inventory, assignments, and team
  members.
- **FR-020**: The system MUST keep a site summary that combines status, inventory risk, workload,
  and budget variance in one place.
- **FR-021**: The system MUST require authentication before any operational screen is reachable.
- **FR-022**: The system MUST store user passwords only as hashes and never return them from the API.
- **FR-023**: The system MUST allow administrators to create users and map users to tenants with an
  access role.
- **FR-024**: The system MUST activate the user's assigned tenant automatically after sign-in.
- **FR-025**: The system MUST restrict tenant administration to users holding the `tenant_admin`
  access role, enforced in both navigation and route entry.

### Key Entities *(include if feature involves data)*

- **Tenant**: The organization context that owns and isolates all business records.
- **Site**: A construction job being tracked, including name, location, status, dates, ownership, and
  financial summary.
- **Inventory Item**: A material or supply tracked for availability, usage, minimum quantity, and related
  site or storage location.
- **Work Assignment**: A unit of work allocated to a person with a site, period, and status.
- **Budget Record**: A planned and actual cost view for a site, including remaining budget and variance.
- **Team Member**: A worker profile with job title and daily pay settings.
- **Team Role Rate**: A reusable title/day-rate definition used by team and workload workflows.
- **App User**: A sign-in identity with credentials and active state.
- **User Tenant Mapping**: The link granting a user access to a tenant under a specific access role.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can create a new site and see it reflected in the site list within 1 minute.
- **SC-002**: At least 90% of site, inventory, workload, budget, and team updates can be completed
  without support assistance.
- **SC-003**: Users can identify low-stock items and budget pressure from payroll directly from
  summary views without manual calculation.
- **SC-004**: A typical site manager can create a site, manage inventory, assign workload by day/date
  range, and review budget in one session.
- **SC-005**: Tenant-isolated data views remain consistent when switching tenant context.
- **SC-006**: Users can delete unwanted workload, inventory, and budget rows with confirmation.
- **SC-007**: A signed-in user reaches their assigned tenant workspace without manual tenant switching.
- **SC-008**: Administration features are not reachable by users lacking the required access role.

## Assumptions

- Users are authenticated before accessing operational data.
- Mobile browser support is expected, but native mobile apps are out of scope.
- Notifications, procurement automation, and detailed accounting integrations remain out of scope.
- Lightweight payroll deduction at workload level is in scope; full payroll processing is out of scope.
- The application focuses on operational tracking rather than advanced forecasting or optimization.
- Self-service registration, password reset, and multi-factor authentication are out of scope;
  administrators provision user accounts.

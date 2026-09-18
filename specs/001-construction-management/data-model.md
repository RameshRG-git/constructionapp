# Data Model: Construction Management Application

## Entities

### Tenant
- Represents an organization/workspace boundary for data isolation.
- Fields: id, name, slug, schema_name, table_prefix, logo_url, primary_color, secondary_color,
  is_active, created_at, updated_at.
- Relationships: one tenant owns many sites, inventory items, assignments, budgets, team members,
  and team role rates.

### Site
- Represents a construction job or site being managed.
- Fields: id, tenant_name, name, site_location, owner_name, planned_start_date, planned_end_date,
  status, created_at, updated_at.
- Status values: planned, active, on_hold, closed.
- Constraints: unique site name per tenant.
- Relationships: has many inventory items, work assignments, and budget records.

### Inventory Item
- Represents a tracked material or supply.
- Fields: id, tenant_name, site_id, item_name, category, unit_of_measure, unit_cost, current_quantity,
  minimum_quantity, storage_location, created_at, updated_at.
- Computed fields in API: low_stock (current_quantity < minimum_quantity) and
  inventory_value (current_quantity * unit_cost).
- Relationships: belongs to a site and tenant; has many inventory transactions.

### Inventory Transaction
- Represents a change in inventory count.
- Fields: id, tenant_name, inventory_item_id, transaction_type, quantity_delta, reference_note,
  performed_by, created_at.
- Transaction types: received, issued, corrected.
- Validation: quantity_delta must be non-zero; issued adjustments cannot drive stock below allowed
  floor without explicit correction.

### Work Assignment
- Represents a unit of work assigned to a person or crew.
- Fields: id, tenant_name, site_id, team_member_id, assignee_type, assignee_name, title, description,
  priority, status, week_start_date, week_end_date, due_date, estimated_hours, work_day_fraction,
  paid_amount, created_at, updated_at.
- `team_member_id` is the relational key used by payroll; `assignee_name` is a display snapshot taken
  at creation/edit time and is not used for matching.
- `work_day_fraction` is `1.0` for a full day or date range, or `0.5` for a half day. Half days are
  only permitted when `week_start_date` equals `week_end_date` (a single-day workload).
- Status values: open, in_progress, blocked, completed.
- Relationships: belongs to a site, tenant, and team member.
- Behavior: past-due/past-period records can be auto-completed by listing logic.

### Budget Record
- Represents planned/actual budget allocations and miscellaneous site expenses.
- Fields: id, tenant_name, site_id, category_name, entry_type, transaction_type, comments,
  planned_amount, actual_amount, remaining_amount, budget_status, recorded_at, updated_at.
- `entry_type` is `allocation` (funds planned/received; the default) or `expense` (an ad-hoc
  miscellaneous cost not tied to a workload or inventory item, e.g. transport, permits, tool rental).
- `recorded_at` is the user-editable transaction date in the budget UI and remains the audit timestamp
  when no date is supplied.
- Transaction types: cash, bank_transfer, upi, cheque, other.
- Budget status values: under_budget, on_budget, over_budget (meaningful for `allocation` rows only).
- Relationships: belongs to a site and tenant.
- Validation: planned_amount and actual_amount must be non-negative; entry_type must be `allocation`
  or `expense`.
- Reporting notes: summary combines workload expense (paid_amount across all assignments), materials
  value (current_quantity * unit_cost across site inventory), and the sum of `expense`-type records
  (misc_expense_total) into total_expense, then reports remaining_budget as the sum of `allocation`-type
  actual amounts minus total_expense.

### Sick Leave
- Represents an employee-wide sick-leave date range; it is not site scoped.
- Fields: id, tenant_name, team_member_id, employee_name, start_date, end_date, reason, created_at,
  updated_at.
- `team_member_id` is the relational key; `employee_name` is a display snapshot.
- Every sick date overlapping a workload period is excluded from days worked, hours, and pay,
  including workloads that span multiple weeks.

### Employee Advance
- Represents money advanced to an employee before normal payroll.
- Fields: id, tenant_name, team_member_id, employee_name, amount, amount_recovered, granted_on,
  due_date, note, created_at, updated_at.
- `team_member_id` is the relational key; `employee_name` is a display snapshot.
- Only advances due on or before the payroll week's Saturday are eligible for recovery.

### Advance Recovery
- Represents an audit entry for recovering part of an employee advance from a payroll week.
- Fields: id, tenant_name, advance_id, team_member_id, employee_name, week_start_date, amount,
  created_at.
- Recoveries are FIFO by due date, capped at that week's net earned pay. Remaining balance carries
  forward, and a week's recovery is committed only when its payment is first recorded.

### Payroll Payment
- Represents the site-level payment record for one employee and one Sunday-to-Saturday week.
- Fields include site_id, team_member_id, employee_name, week_start_date, week_end_date, days_worked,
  earned_amount, advance_recovery_amount, paid_amount, status, payment_method, note, and paid_on.
- `team_member_id` is the relational key (unique per tenant/site/week/team_member_id); `employee_name`
  is a display snapshot, so renaming a team member does not disconnect historical payroll data.
- Computed values include sick_days, net_payable_amount, outstanding_amount, and advance_balance.

### App User
- Represents a person who can sign in to the application.
- Fields: id, username, email, full_name, password_hash, is_active, created_at, updated_at.
- Constraints: username and email are globally unique.
- Security: password is stored only as a salted hash and is never returned by the API.
- Relationships: has many tenant mappings, removed together with the user.

### User Tenant Mapping
- Represents which tenants a user may access and with what role.
- Fields: id, user_id, tenant_id, tenant_slug, access_role, is_active, created_at, updated_at.
- Constraints: unique (user_id, tenant_id); deletes cascade from both user and tenant.
- Access roles: admin, tenant_admin, project_management, site_operations, warehouse_control,
  finance_review.
- Behavior: the first active mapping determines the tenant activated after sign-in.

### Team Member
- Represents a worker profile available for workload assignment.
- Fields: id, tenant_name, full_name, job_title, daily_pay_rate, app_access_planned, access_email,
  access_role, is_active, created_at, updated_at.
- `id` is the relational key used by work assignments, sick leave, employee advances, advance
  recoveries, and payroll payments; renaming a member does not break historical records because
  those records keep their own display-name snapshot.

### Team Role Rate
- Represents reusable title/day-rate definitions.
- Fields: id, tenant_name, title, daily_pay_rate, sort_order, is_active, created_at, updated_at.
- Constraints: unique (tenant_name, title).
- Behavior: default role set is auto-seeded when a tenant has no role entries.

### User Role
- Represents the permissions granted to a user.
- Fields: id, role_name, permissions.
- Core roles: site_management, site_operations, warehouse_control, finance_review.
- Relationships: assigned to users and evaluated by authorization rules.

### Site Summary View
- Represents the combined operational view shown to users.
- Fields: site status, inventory risk count, workload distribution, budget variance, last updated.
- Relationships: derived from site, inventory item, work assignment, and budget record data within
  a tenant boundary.
- Validation: computed values must stay in sync with underlying records.

## Relationships
- One tenant has many sites.
- One tenant has many team members.
- One tenant has many team role rates.
- One site has many inventory items.
- One site has many work assignments.
- One site has many budget records (allocations and miscellaneous expenses).
- One tenant has many sick leaves and employee advances.
- One employee advance has many advance recovery records.
- One site has many weekly payroll payment records.
- One team member has many work assignments, sick leaves, employee advances, and payroll payments
  (related by team_member_id).
- One inventory item has many inventory transactions.
- One user role can be assigned to many users.
- One app user has many tenant mappings, and one tenant has many user mappings.

## State Transitions
- Site: planned -> active -> on_hold -> active -> closed.
- Work assignment: open -> in_progress -> blocked -> in_progress -> completed.
- Inventory item low-stock flag: false -> true when current quantity drops below minimum quantity,
  and true -> false when restocked.
- Budget record status: under_budget -> on_budget -> over_budget as actual amounts change.

## Validation Rules
- Site names must be present and unique within each tenant.
- Inventory quantities and budget amounts must not be negative.
- Due dates for work assignments must not precede the assignment creation date.
- Work assignments require a valid `team_member_id`; `work_day_fraction` must be `0.5` or `1.0`, and
  `0.5` is only allowed when the workload is a single day.
- Closed sites should reject new operational changes except authorized reopening workflows.
- Team role titles must be unique within each tenant.
- Delete operations for inventory items, assignments, and budget records must be scoped to tenant.
- Sick leave and employee advance records require a valid `team_member_id`; sick leave end dates
  cannot precede start dates.
- Advance amounts must be positive; recovery cannot exceed the advance balance or that week's net pay.
- Budget records require `entry_type` to be `allocation` or `expense`.
- Usernames must be at least 3 characters and emails must be well formed and unique.
- Passwords must be at least 8 characters and are never stored or returned in plaintext.
- A user may be mapped to a given tenant only once, and the access role must be a supported value.

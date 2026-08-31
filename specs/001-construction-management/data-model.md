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
- Fields: id, tenant_name, site_id, assignee_type, assignee_name, title, description, priority,
  status, week_start_date, week_end_date, due_date, estimated_hours, paid_amount, created_at,
  updated_at.
- Status values: open, in_progress, blocked, completed.
- Relationships: belongs to a site and tenant.
- Behavior: past-due/past-period records can be auto-completed by listing logic.

### Budget Record
- Represents planned and actual financial tracking for a site.
- Fields: id, tenant_name, site_id, category_name, planned_amount, actual_amount, remaining_amount,
  budget_status, recorded_at, updated_at.
- Budget status values: under_budget, on_budget, over_budget.
- Relationships: belongs to a site and tenant.
- Validation: planned_amount and actual_amount must be non-negative.
- Reporting notes: summary combines workload expense (paid_amount across all assignments) and
  materials value (current_quantity * unit_cost across site inventory) into total_expense, then
  reports remaining_budget as actual_total - total_expense.

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
- Relationships: belongs to tenant; referenced by assignment workflows through selected assignee name
  and role title.

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
- One site has many budget records.
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
- Closed sites should reject new operational changes except authorized reopening workflows.
- Team role titles must be unique within each tenant.
- Delete operations for inventory items, assignments, and budget records must be scoped to tenant.
- Usernames must be at least 3 characters and emails must be well formed and unique.
- Passwords must be at least 8 characters and are never stored or returned in plaintext.
- A user may be mapped to a given tenant only once, and the access role must be a supported value.

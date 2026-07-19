# Data Model: Construction Management Application

## Entities

### Site
- Represents a construction job or site being managed.
- Fields: id, name, site_location, owner_name, planned_start_date, planned_end_date, status,
  created_at, updated_at.
- Status values: planned, active, on_hold, closed.
- Relationships: has many inventory items, work assignments, and budget records.

### Inventory Item
- Represents a tracked material or supply.
- Fields: id, site_id, item_name, category, unit_of_measure, current_quantity, minimum_quantity,
  low_stock_flag, storage_location, created_at, updated_at.
- Relationships: belongs to a site; has many inventory transactions.

### Inventory Transaction
- Represents a change in inventory count.
- Fields: id, inventory_item_id, transaction_type, quantity_delta, reference_note, performed_by,
  created_at.
- Transaction types: received, issued, corrected.
- Validation: quantity_delta must be non-zero; issued adjustments cannot drive stock below allowed
  floor without explicit correction.

### Work Assignment
- Represents a unit of work assigned to a person or crew.
- Fields: id, site_id, assignee_type, assignee_name, title, description, priority, status, due_date,
  estimated_hours, created_at, updated_at.
- Status values: open, in_progress, blocked, completed.
- Relationships: belongs to a site.

### Budget Record
- Represents planned and actual financial tracking for a site.
- Fields: id, site_id, category_name, planned_amount, actual_amount, remaining_amount,
  budget_status, recorded_at, updated_at.
- Budget status values: under_budget, on_budget, over_budget.
- Relationships: belongs to a site.
- Validation: planned_amount and actual_amount must be non-negative.

### User Role
- Represents the permissions granted to a user.
- Fields: id, role_name, permissions.
- Core roles: project_management, site_operations, warehouse_control, finance_review.
- Relationships: assigned to users and evaluated by authorization rules.

### Site Summary View
- Represents the combined operational view shown to users.
- Fields: site status, inventory risk count, workload distribution, budget variance, last updated.
- Relationships: derived from site, inventory item, work assignment, and budget record data.
- Validation: computed values must stay in sync with underlying records.

## Relationships
- One site has many inventory items.
- One site has many work assignments.
- One site has many budget records.
- One inventory item has many inventory transactions.
- One user role can be assigned to many users.

## State Transitions
- Site: planned -> active -> on_hold -> active -> closed.
- Work assignment: open -> in_progress -> blocked -> in_progress -> completed.
- Inventory item low-stock flag: false -> true when current quantity drops below minimum quantity,
  and true -> false when restocked.
- Budget record status: under_budget -> on_budget -> over_budget as actual amounts change.

## Validation Rules
- Site names must be present and unique within the operating workspace.
- Inventory quantities and budget amounts must not be negative.
- Due dates for work assignments must not precede the assignment creation date.
- Closed sites should reject new operational changes except authorized reopening workflows.

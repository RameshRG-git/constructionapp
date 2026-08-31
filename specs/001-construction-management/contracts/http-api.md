# HTTP API Contract: Construction Management Application

## Overview
The frontend communicates with the Flask backend through JSON over HTTP. All mutating requests must
be authorized, validated server-side, and return actionable error responses.

## Common Conventions
- Base path: `/api/v1`
- Content type: `application/json`
- Tenant routing: `X-Tenant` request header (falls back to configured default tenant)
- Authentication: signed server-side session cookie issued by `POST /auth/login`
- Authorization: tenant access roles are attached through user-to-tenant mappings
- Error response shape:
```json
{
  "error": {
    "code": "string",
    "message": "string",
    "details": []
  }
}
```

## Endpoints

### Authentication
- `POST /auth/login` - sign in with `identifier` (username or email) and `password`
- `POST /auth/logout` - clear the active session
- `GET /auth/session` - return the current session context, or `401` when unauthenticated

Session payload returned by login and session:
- `user` - user profile without password data
- `tenants` - active tenant mappings for the user
- `access_roles` - distinct access roles across those mappings
- `default_tenant` - tenant slug the client should activate after sign-in
- `is_tenant_admin` - `true` when the user holds the `tenant_admin` role

### Sites
- `GET /sites` - list sites with summary fields
- `POST /sites` - create a site
- `GET /sites/{site_id}` - fetch site detail and operational summary
- `PATCH /sites/{site_id}` - update site metadata or status
- `POST /sites/{site_id}/close` - close a site

Query parameters for `GET /sites`:
- `status`
- `owner_name`
- `q`
- `sort_by` (`name`, `site_location`, `owner_name`, `planned_start_date`, `planned_end_date`, `status`, `created_at`)
- `sort_order` (`asc`, `desc`)

### Inventory
- `GET /inventory` - list tenant inventory; optional site filter
- `GET /sites/{site_id}/inventory` - list tracked inventory items for a site
- `POST /sites/{site_id}/inventory` - create a tracked inventory item
- `PATCH /inventory/{item_id}` - update inventory item metadata or thresholds
- `DELETE /inventory/{item_id}` - delete inventory item
- `POST /inventory/{item_id}/transactions` - record a received, issued, or corrected stock change

Query parameters for inventory lists:
- `site_id` (global endpoint only)
- `category`
- `low_stock` (`true`, `false`)
- `sort_by` (`item_name`, `category`, `current_quantity`, `minimum_quantity`)
- `sort_order` (`asc`, `desc`)

Inventory item payload includes `unit_cost` and derived `inventory_value`
(`current_quantity * unit_cost`).

### Workloads
- `GET /sites/{site_id}/assignments` - list work assignments
- `POST /sites/{site_id}/assignments` - create a work assignment
- `PATCH /assignments/{assignment_id}` - update assignment details and status
- `DELETE /assignments/{assignment_id}` - delete assignment

Query parameters for workload list:
- `status`
- `assignee`
- `q`
- `on_date`
- `from_date`
- `to_date`
- `week_start`
- `include_past` (`true`, `false`)
- `sort_by` (`week_start_date`, `due_date`, `priority`, `assignee_name`, `status`)
- `sort_order` (`asc`, `desc`)

### Budgets
- `GET /sites/{site_id}/budgets` - list budget records and summary
- `POST /sites/{site_id}/budgets` - create a budget record
- `PATCH /budgets/{budget_id}` - update planned or actual amounts
- `DELETE /budgets/{budget_id}` - delete budget record

Budget summary payload includes:
- `planned_total`
- `actual_total`
- `payroll_total` - workload expense across all assignment statuses
- `inventory_expense_total` - materials value across site inventory
- `total_expense` - `payroll_total + inventory_expense_total`
- `remaining_budget` - `actual_total - total_expense`
- `variance` - `total_expense - planned_total`

### Team Management
- `GET /team-members` - list team members
- `POST /team-members` - create a team member
- `PATCH /team-members/{member_id}` - update team member
- `GET /team-roles` - list role/day-rate catalog (auto-seeds defaults if empty)
- `POST /team-roles` - create role/day-rate entry
- `PATCH /team-roles/{role_id}` - update role/day-rate entry

### Tenant Management
- `GET /tenants` - list tenants
- `POST /tenants` - create tenant
- `GET /tenants/current` - get current tenant context

### User Administration
- `GET /users` - list application users with their tenant mappings
- `POST /users` - create an application user
- `PATCH /users/{user_id}` - update profile, password, or active state
- `DELETE /users/{user_id}` - delete a user and its tenant mappings
- `GET /user-tenants` - list user-to-tenant mappings; supports `user_id` and `tenant_slug` filters
- `POST /user-tenants` - map a user to a tenant with an access role
- `PATCH /user-tenants/{mapping_id}` - update mapping access role or active state
- `DELETE /user-tenants/{mapping_id}` - remove a mapping

Supported access roles: `admin`, `tenant_admin`, `project_management`, `site_operations`,
`warehouse_control`, `finance_review`.

### Reporting
- `GET /sites/{site_id}/summary` - return combined site health, inventory risk, workload,
  and budget variance data for the dashboard
- `GET /reports/overview` - return organization-wide operational summary data for charts

## Validation Expectations
- Site creation requires name, site location, owner, planned start date, and planned end date.
- Inventory transactions require a valid transaction type and a non-zero quantity delta.
- Work assignments require assignee, title, and due date/period fields.
- Budget records require non-negative planned and actual amounts.
- Team members require full_name, job_title, and daily_pay_rate.
- Team role rates require title and daily_pay_rate.
- Users require a unique username (minimum 3 characters), unique valid email, full name, and a
  password of at least 8 characters stored only as a hash.
- User-tenant mappings require an existing user, an existing tenant, a supported access role, and
  must be unique per user and tenant pair.
- Failed sign-in attempts return `401` with a single generic message for unknown users, inactive
  users, and wrong passwords.
- Unauthorized requests must return `401` or `403` with a clear error code.

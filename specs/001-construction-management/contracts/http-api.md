# HTTP API Contract: Construction Management Application

## Overview
The frontend communicates with the Flask backend through JSON over HTTP. All mutating requests must
be authorized, validated server-side, and return actionable error responses.

## Common Conventions
- Base path: `/api/v1`
- Content type: `application/json`
- Authentication: browser-friendly authenticated session with role-based authorization enforced by the
  backend
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

### Projects
- `GET /projects` - list projects with summary fields
- `POST /projects` - create a project
- `GET /projects/{project_id}` - fetch project detail and operational summary
- `PATCH /projects/{project_id}` - update project metadata or status
- `POST /projects/{project_id}/close` - close a project

### Inventory
- `GET /projects/{project_id}/inventory` - list tracked inventory items for a project
- `POST /projects/{project_id}/inventory` - create a tracked inventory item
- `PATCH /inventory/{item_id}` - update inventory item metadata or thresholds
- `POST /inventory/{item_id}/transactions` - record a received, issued, or corrected stock change

### Workloads
- `GET /projects/{project_id}/assignments` - list work assignments
- `POST /projects/{project_id}/assignments` - create a work assignment
- `PATCH /assignments/{assignment_id}` - update assignment details and status

### Budgets
- `GET /projects/{project_id}/budgets` - list budget records and summary
- `POST /projects/{project_id}/budgets` - create a budget record
- `PATCH /budgets/{budget_id}` - update planned or actual amounts

### Reporting
- `GET /projects/{project_id}/summary` - return combined project health, inventory risk, workload,
  and budget variance data for the dashboard
- `GET /reports/overview` - return organization-wide operational summary data for charts

## Validation Expectations
- Project creation requires name, site location, owner, planned start date, and planned end date.
- Inventory transactions require a valid transaction type and a non-zero quantity delta.
- Work assignments require assignee, title, due date, and status.
- Budget records require non-negative planned and actual amounts.
- Unauthorized requests must return `401` or `403` with a clear error code.

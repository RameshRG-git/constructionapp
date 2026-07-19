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

### Sites
- `GET /sites` - list sites with summary fields
- `POST /sites` - create a site
- `GET /sites/{site_id}` - fetch site detail and operational summary
- `PATCH /sites/{site_id}` - update site metadata or status
- `POST /sites/{site_id}/close` - close a site

### Inventory
- `GET /sites/{site_id}/inventory` - list tracked inventory items for a site
- `POST /sites/{site_id}/inventory` - create a tracked inventory item
- `PATCH /inventory/{item_id}` - update inventory item metadata or thresholds
- `POST /inventory/{item_id}/transactions` - record a received, issued, or corrected stock change

### Workloads
- `GET /sites/{site_id}/assignments` - list work assignments
- `POST /sites/{site_id}/assignments` - create a work assignment
- `PATCH /assignments/{assignment_id}` - update assignment details and status

### Budgets
- `GET /sites/{site_id}/budgets` - list budget records and summary
- `POST /sites/{site_id}/budgets` - create a budget record
- `PATCH /budgets/{budget_id}` - update planned or actual amounts

### Reporting
- `GET /sites/{site_id}/summary` - return combined site health, inventory risk, workload,
  and budget variance data for the dashboard
- `GET /reports/overview` - return organization-wide operational summary data for charts

## Validation Expectations
- Site creation requires name, site location, owner, planned start date, and planned end date.
- Inventory transactions require a valid transaction type and a non-zero quantity delta.
- Work assignments require assignee, title, due date, and status.
- Budget records require non-negative planned and actual amounts.
- Unauthorized requests must return `401` or `403` with a clear error code.

# Tenant Creation Setup

This guide explains how to create and activate tenants in the Construction Management application.

## Default Tenant

- Default tenant slug: `kaniskahomes`
- Default tenant display name: `KaniskaHomes`
- This tenant is auto-seeded during backend startup if it does not exist.

## Multi-Tenant Model

- Tenant is resolved from `X-Tenant` request header.
- If no header is provided, backend uses `DEFAULT_TENANT` from config.
- Operational data is tenant-scoped using `tenant_name` across Sites, Inventory, Workloads, and Budgets.
- Tenant metadata stores:
  - `schema_name` (for schema namespace, e.g. `tenant_kaniskahomes`)
  - `table_prefix` (for table namespace conventions, e.g. `kaniskahomes_`)
  - branding (`logo_url`, `primary_color`, `secondary_color`)

## Backend Configuration

Set environment variables as needed:

```bash
export DEFAULT_TENANT=kaniskahomes
export DATABASE_URL=postgresql+psycopg://constructionapp:constructionapp@localhost:5432/constructionapp
```

## Tenant APIs

- `GET /api/v1/tenants` list all tenants
- `POST /api/v1/tenants` create a tenant
- `GET /api/v1/tenants/current` get current tenant context

Example create payload:

```json
{
  "name": "Acme Infra",
  "slug": "acmeinfra",
  "schema_name": "tenant_acmeinfra",
  "table_prefix": "acmeinfra_",
  "logo_url": "https://cdn.example.com/acme/logo.png",
  "primary_color": "#114B5F",
  "secondary_color": "#1A936F",
  "is_active": true
}
```

## Tenant Admin Page

Use the UI route below to manage tenants:

- `/tenant-admin`

Capabilities:
- Create new tenant records
- View schema and table-prefix settings
- Switch active tenant context in the frontend client

## Notes

- Tenant schema is created on tenant creation for PostgreSQL deployments.
- The frontend sends tenant context in every API call with `X-Tenant`.
- To apply per-tenant branding, configure `logo_url`, `primary_color`, and `secondary_color`.

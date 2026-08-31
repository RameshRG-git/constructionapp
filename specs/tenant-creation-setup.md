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

Related tenant-scoped operational APIs:
- `GET /api/v1/sites`
- `GET /api/v1/inventory` (optional `site_id` filter)
- `GET /api/v1/team-members`
- `GET /api/v1/team-roles`

## User APIs

- `GET /api/v1/users` list users with their tenant mappings
- `POST /api/v1/users` create a user
- `PATCH /api/v1/users/{user_id}` update profile, password, or active state
- `DELETE /api/v1/users/{user_id}` delete a user and its mappings
- `GET /api/v1/user-tenants` list mappings
- `POST /api/v1/user-tenants` map a user to a tenant
- `PATCH /api/v1/user-tenants/{mapping_id}` update mapping role or active state
- `DELETE /api/v1/user-tenants/{mapping_id}` remove a mapping

Example mapping payload:

```json
{
  "user_id": 1,
  "tenant_id": 2,
  "access_role": "tenant_admin",
  "is_active": true
}
```

Supported access roles: `admin`, `tenant_admin`, `project_management`, `site_operations`,
`warehouse_control`, `finance_review`.

## Authentication APIs

- `POST /api/v1/auth/login` sign in with `identifier` (username or email) and `password`
- `POST /api/v1/auth/logout` end the session
- `GET /api/v1/auth/session` read the current session context

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

Access to this route requires a signed-in user holding the `tenant_admin` access role. The route is
hidden from navigation and blocked on direct entry for everyone else.

Capabilities:
- Create new tenant records
- View schema and table-prefix settings
- Switch active tenant context in the frontend client
- Create application users and activate, deactivate, or delete them
- Map users to tenants and manage their access roles

## Notes

- Tenant schema is created on tenant creation for PostgreSQL deployments.
- The frontend sends tenant context in every API call with `X-Tenant`.
- To apply per-tenant branding, configure `logo_url`, `primary_color`, and `secondary_color`.
- Team role/day-rate defaults are auto-seeded for a tenant the first time role catalog is requested.
- After sign-in, the client activates the tenant from the user's first active mapping.
- A new tenant is only reachable in the UI once at least one user is mapped to it.

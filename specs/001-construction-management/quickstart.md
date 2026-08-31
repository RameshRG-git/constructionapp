# Quickstart: Construction Management Application

## Prerequisites
- Python 3.11+
- Flutter 3.x
- PostgreSQL 15+
- Git

## Local Setup
1. Clone the repository and switch to the feature branch.
2. Create a PostgreSQL database for the application.
3. Set backend environment variables for database connectivity, Flask app factory, and default tenant.
4. Install backend and frontend dependencies.

## Backend
1. Create and activate a Python virtual environment.
2. Install backend dependencies.
3. Run database migrations.
4. Start the Flask API server.
5. Run backend tests with PyTest.

Example commands once the scaffold exists:
```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -e .[dev]
export FLASK_APP=app:create_app
export DEFAULT_TENANT=kaniskahomes
export SECRET_KEY="replace-with-a-strong-random-value"
flask db upgrade
flask run --host 127.0.0.1 --port 5000
pytest
```

## Frontend
1. Install Flutter dependencies.
2. Launch the Flutter web client in Chrome or another supported browser.
3. Sign in, then verify sites, materials, workloads, budgets, and team screens load correctly.

Example commands once the scaffold exists:
```bash
cd frontend
flutter pub get
flutter run -d chrome
flutter analyze
flutter test
```

## Tenant Context
- All API calls are tenant-scoped through `X-Tenant`.
- If not supplied, backend falls back to `DEFAULT_TENANT` (default `kaniskahomes`).
- After sign-in the client activates the tenant returned as `default_tenant` for that user.
- Use the tenant admin workflow to create additional tenant workspaces.

## Authentication and Access
- Users sign in at `/login` with username or email plus password.
- Sessions are tracked with a signed server-side cookie; set a strong `SECRET_KEY` outside local dev.
- Tenant Admin is hidden from navigation and blocked on direct navigation unless the signed-in user
  holds the `tenant_admin` access role.
- Manage users and user-to-tenant mappings from the Tenant Admin screen.

Bootstrap the first administrator on an empty database:

```bash
cd /home/ubuntu/projects/constructionapp/backend
source .venv/bin/activate
python -c "
from app import create_app
from app.models.tenant import Tenant
from app.services.user_service import UserService
app = create_app()
with app.app_context():
    user = UserService.create_user('admin', 'admin@example.com', 'Platform Admin', 'ChangeMe123!')
    tenant = Tenant.query.filter(Tenant.slug == 'kaniskahomes').first()
    UserService.map_user_to_tenant(user_id=user.id, tenant_id=tenant.id, access_role='tenant_admin')
"
```

Change the bootstrap password immediately after the first sign-in.

## Functional Smoke Checklist
- Sign in and confirm the session activates the mapped tenant.
- Confirm Tenant Admin appears only for `tenant_admin` users.
- Create a user and map it to a tenant from Tenant Admin.
- Create and update a site.
- Add a materials item with unit cost, edit it, and delete it.
- Add workload for one day and for a date range; verify older periods auto-complete.
- Verify workloads default to the Open filter and that All includes completed records.
- Add a budget record, verify summary totals (actual, workload expense, materials value, total
  expense, remaining), then delete a record.
- Add team member and role/day-rate entry.
- Sign out and confirm protected routes redirect to login.

## CI/CD
- Run backend and frontend checks before deployment:
	- backend: `pytest`
	- frontend: `flutter analyze` and `flutter test`
- Production releases should be based on passing checks and reviewed commits.

## Deployment Topology
- Backend Flask API listens on `127.0.0.1:5000`.
- Frontend release build is synced to `/var/www/kaniskahomes/`.
- nginx serves the site on ports `80` and `443`, redirects HTTP to HTTPS, and proxies `/api/v1`
  to the backend.

## Post-Change Runbook

Use this sequence after backend or frontend code changes.

### 1) Restart backend service

Before restart, always apply schema migrations:

```bash
cd /home/ubuntu/projects/constructionapp/backend
source .venv/bin/activate
FLASK_APP=app:create_app flask db upgrade
```

If `flask db upgrade` fails with `DuplicateTable`, the tables were already created by the startup
`db.create_all()` call. Verify the live schema matches the migration, then align the revision:

```bash
FLASK_APP=app:create_app flask db stamp head
FLASK_APP=app:create_app flask db current
```

Preferred (systemd-managed service):

```bash
sudo systemctl restart constructionapp-backend && curl -s -o /dev/null -w "api_health:%{http_code}\n" http://127.0.0.1:5000/api/v1/health
```

Fallback (if port 5000 is held by a stale process):

```bash
PID=$(lsof -tiTCP:5000 -sTCP:LISTEN)
if [ -n "$PID" ]; then
	kill "$PID"
fi
cd /home/ubuntu/projects/constructionapp/backend
source .venv/bin/activate
FLASK_APP=app:create_app flask db upgrade
FLASK_APP=app:create_app python -m flask run --host 127.0.0.1 --port 5000
```

Quick health check only:

```bash
curl -s -o /dev/null -w "api_health:%{http_code}\n" http://127.0.0.1:5000/api/v1/health
```

### 2) Build frontend

```bash
cd /home/ubuntu/projects/constructionapp/frontend
/home/ubuntu/flutter/bin/flutter pub get
/home/ubuntu/flutter/bin/flutter build web --release
```

### 3) Sync deploy files

Primary deploy sync:

```bash
cd /home/ubuntu/projects/constructionapp/frontend
sudo rsync -av --delete build/web/ /var/www/kaniskahomes/
```

Equivalent sync command (same source and target):

```bash
sudo rsync -av --delete build/web/ /var/www/kaniskahomes/
```

### 4) Verify deployed frontend

```bash
curl -sk -L -o /dev/null -w "site:%{http_code}\n" http://127.0.0.1/
curl -sk -L -o /dev/null -w "api_health:%{http_code}\n" http://127.0.0.1/api/v1/health
curl -sk -L -o /dev/null -w "auth_session:%{http_code}\n" http://127.0.0.1/api/v1/auth/session
ls -la /var/www/kaniskahomes/
```

An unauthenticated `auth_session` check returns `401`, which is the expected result.

### 5) Recommended full sequence after any code change

```bash
# backend
cd /home/ubuntu/projects/constructionapp/backend
source .venv/bin/activate
FLASK_APP=app:create_app flask db upgrade
sudo systemctl restart constructionapp-backend
curl -s -o /dev/null -w "api_health:%{http_code}\n" http://127.0.0.1:5000/api/v1/health

# frontend build + deploy sync
cd /home/ubuntu/projects/constructionapp/frontend
/home/ubuntu/flutter/bin/flutter analyze
/home/ubuntu/flutter/bin/flutter pub get
/home/ubuntu/flutter/bin/flutter build web --release
sudo rsync -av --delete build/web/ /var/www/kaniskahomes/

# optional frontend health check
curl -sk -L -o /dev/null -w "site:%{http_code}\n" http://127.0.0.1/
```

# Quickstart: Construction Management Application

## Prerequisites
- Python 3.11+
- Flutter 3.x
- PostgreSQL 15+
- Git

## Local Setup
1. Clone the repository and switch to the feature branch.
2. Create a PostgreSQL database for the application.
3. Set backend environment variables for database connectivity and secret configuration.
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
pip install -r requirements.txt
flask db upgrade
flask run
pytest
```

## Frontend
1. Install Flutter dependencies.
2. Launch the Flutter web client in Chrome or another supported browser.
3. Verify site dashboards, inventory summaries, workload views, and budget charts load correctly.

Example commands once the scaffold exists:
```bash
cd frontend
flutter pub get
flutter run -d chrome
flutter test
```

## Reporting Views
- Dashboard and reporting pages consume aggregated API data.
- Chart.js renders site health, inventory risk, workload spread, and budget variance charts.

## CI/CD
- GitLab CI should run backend tests, frontend tests, and build checks on every merge request.
- Production releases should be based on a passing pipeline and a reviewed merge commit.

## Post-Change Runbook

Use this sequence after backend or frontend code changes.

### 1) Restart backend service

Before restart, always apply schema migrations:

```bash
cd /home/ubuntu/projects/constructionapp/backend
source .venv/bin/activate
FLASK_APP=app:create_app flask db upgrade
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
curl -I http://127.0.0.1:8080
ls -la /var/www/kaniskahomes/
```

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
/home/ubuntu/flutter/bin/flutter pub analyze
/home/ubuntu/flutter/bin/flutter pub get
/home/ubuntu/flutter/bin/flutter build web --release
sudo rsync -av --delete build/web/ /var/www/kaniskahomes/
```

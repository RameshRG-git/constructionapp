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
3. Verify project dashboards, inventory summaries, workload views, and budget charts load correctly.

Example commands once the scaffold exists:
```bash
cd frontend
flutter pub get
flutter run -d chrome
flutter test
```

## Reporting Views
- Dashboard and reporting pages consume aggregated API data.
- Chart.js renders project health, inventory risk, workload spread, and budget variance charts.

## CI/CD
- GitLab CI should run backend tests, frontend tests, and build checks on every merge request.
- Production releases should be based on a passing pipeline and a reviewed merge commit.

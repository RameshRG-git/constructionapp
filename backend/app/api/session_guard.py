from flask import g, jsonify, request, session

from ..services.session_service import SessionService
from ..services.tenancy import get_request_tenant_name
from ..services.user_service import TENANT_ADMIN_ROLE

SESSION_TOKEN_KEY = "sid"

PUBLIC_PATHS = {"/api/v1/health", "/api/v1/auth/login", "/api/v1/auth/logout"}
ADMIN_PATH_PREFIXES = ("/api/v1/users", "/api/v1/user-tenants")


def _error(status, code, message):
    response = jsonify({"error": {"code": code, "message": message}})
    response.status_code = status
    return response


def register_session_guard(app):
    @app.before_request
    def enforce_session():
        path = request.path.rstrip("/") or "/"
        if not path.startswith("/api/") or path in PUBLIC_PATHS:
            return None

        record, error_code = SessionService.validate(session.get(SESSION_TOKEN_KEY))
        user = record.user if record else None
        if user is None or not user.is_active:
            session.clear()
            if error_code == "session_expired":
                return _error(401, "session_expired", "Your session has expired. Please sign in again.")
            return _error(401, "unauthorized", "Authentication required")

        active_links = [link for link in user.tenant_links if link.is_active]
        is_tenant_admin = any(link.access_role == TENANT_ADMIN_ROLE for link in active_links)

        # Auth endpoints run before the client knows which tenant to use.
        if not path.startswith("/api/v1/auth/") and not is_tenant_admin:
            if get_request_tenant_name() not in {link.tenant_slug for link in active_links}:
                return _error(403, "tenant_forbidden", "You do not have access to this tenant")

        is_admin_path = path.startswith(ADMIN_PATH_PREFIXES) or (
            path == "/api/v1/tenants" and request.method != "GET"
        )
        if is_admin_path and not is_tenant_admin:
            return _error(403, "forbidden", "Tenant administrator access required")

        g.current_user = user
        g.user_session = record
        SessionService.touch(record)
        return None

    @app.after_request
    def prevent_api_caching(response):
        if request.path.startswith("/api/"):
            response.headers["Cache-Control"] = "no-store"
            response.headers["Pragma"] = "no-cache"
            response.headers["X-Content-Type-Options"] = "nosniff"
        return response

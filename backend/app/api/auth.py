from flask import Blueprint, abort, g, request, session

from .response import ok
from .session_guard import SESSION_TOKEN_KEY
from ..models.app_user import AppUser
from ..services.session_service import SessionService
from ..services.user_service import TENANT_ADMIN_ROLE, UserService


auth_bp = Blueprint("auth", __name__)


def _session_payload(user, record=None):
    active_links = [link for link in user.tenant_links if link.is_active]
    tenants = [link.to_dict() for link in active_links]
    access_roles = sorted({link.access_role for link in active_links})
    return {
        "user": user.to_dict(),
        "tenants": tenants,
        "access_roles": access_roles,
        "default_tenant": tenants[0]["tenant_slug"] if tenants else None,
        "is_tenant_admin": TENANT_ADMIN_ROLE in access_roles,
        "session": {
            "idle_timeout_seconds": int(SessionService.idle_timeout().total_seconds()),
            "absolute_expires_at": record.absolute_expires_at.isoformat() + "Z" if record else None,
        },
    }


@auth_bp.post("/auth/login")
def login():
    payload = request.get_json(force=True)
    identifier = (payload.get("identifier") or payload.get("username") or "").strip().lower()
    password = payload.get("password") or ""

    user = AppUser.query.filter(
        (AppUser.username == identifier) | (AppUser.email == identifier)
    ).first()

    # Same response for unknown user, inactive user, and bad password.
    if not user or not user.is_active or not UserService.verify_password(user, password):
        abort(401, description="Invalid username or password")

    # Drop any pre-login session state and issue a fresh token (prevents session fixation).
    SessionService.revoke(session.get(SESSION_TOKEN_KEY))
    session.clear()
    token = SessionService.create(user)
    session[SESSION_TOKEN_KEY] = token
    session.permanent = True
    record, _ = SessionService.validate(token)
    return ok(_session_payload(user, record))


@auth_bp.post("/auth/logout")
def logout():
    SessionService.revoke(session.get(SESSION_TOKEN_KEY))
    session.clear()
    return ok({"logged_out": True})


@auth_bp.get("/auth/session")
def current_session():
    return ok(_session_payload(g.current_user, g.user_session))

from flask import Blueprint, abort, request, session

from .response import ok
from ..models.app_user import AppUser
from ..services.user_service import TENANT_ADMIN_ROLE, UserService


auth_bp = Blueprint("auth", __name__)

SESSION_USER_KEY = "auth_user_id"


def _session_payload(user):
    active_links = [link for link in user.tenant_links if link.is_active]
    tenants = [link.to_dict() for link in active_links]
    access_roles = sorted({link.access_role for link in active_links})
    return {
        "user": user.to_dict(),
        "tenants": tenants,
        "access_roles": access_roles,
        "default_tenant": tenants[0]["tenant_slug"] if tenants else None,
        "is_tenant_admin": TENANT_ADMIN_ROLE in access_roles,
    }


def _load_session_user():
    user_id = session.get(SESSION_USER_KEY)
    if not user_id:
        return None
    user = AppUser.query.filter(AppUser.id == user_id).first()
    if not user or not user.is_active:
        session.clear()
        return None
    return user


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

    session.clear()
    session[SESSION_USER_KEY] = user.id
    session.permanent = True
    return ok(_session_payload(user))


@auth_bp.post("/auth/logout")
def logout():
    session.clear()
    return ok({"logged_out": True})


@auth_bp.get("/auth/session")
def current_session():
    user = _load_session_user()
    if not user:
        abort(401, description="Not authenticated")
    return ok(_session_payload(user))

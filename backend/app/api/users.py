from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.app_user import AppUser
from ..models.user_tenant import UserTenant
from ..services.user_service import TENANT_ACCESS_ROLES, UserService


users_bp = Blueprint("users", __name__)


@users_bp.get("/users")
def list_users():
    query = AppUser.query

    search = request.args.get("q", "").strip()
    if search:
        query = query.filter(
            AppUser.username.ilike(f"%{search}%")
            | AppUser.email.ilike(f"%{search}%")
            | AppUser.full_name.ilike(f"%{search}%")
        )

    include_inactive = request.args.get("include_inactive", "false").lower() == "true"
    if not include_inactive:
        query = query.filter(AppUser.is_active.is_(True))

    sortable = {
        "username": AppUser.username,
        "email": AppUser.email,
        "full_name": AppUser.full_name,
        "created_at": AppUser.created_at,
    }
    sort_column = sortable.get(request.args.get("sort_by", "username"), AppUser.username)
    if request.args.get("sort_order", "asc") == "desc":
        sort_column = sort_column.desc()

    users = query.order_by(sort_column, AppUser.id.desc()).all()
    return ok({"items": [user.to_dict(include_tenants=True) for user in users]})


@users_bp.post("/users")
def create_user():
    payload = request.get_json(force=True)
    user = UserService.create_user(
        username=payload.get("username"),
        email=payload.get("email"),
        full_name=payload.get("full_name"),
        password=payload.get("password"),
        is_active=payload.get("is_active", True),
    )
    return created(user.to_dict(include_tenants=True))


@users_bp.patch("/users/<int:user_id>")
def update_user(user_id):
    payload = request.get_json(force=True)
    user = AppUser.query.filter(AppUser.id == user_id).first_or_404()

    if "full_name" in payload:
        full_name = (payload["full_name"] or "").strip()
        if not full_name:
            raise ValueError("full_name is required")
        user.full_name = full_name
    if "email" in payload:
        email = UserService.normalize_email(payload["email"])
        if AppUser.query.filter(AppUser.email == email, AppUser.id != user.id).first():
            raise ValueError("email already exists")
        user.email = email
    if "password" in payload and payload["password"]:
        user.password_hash = UserService.hash_password(payload["password"])
    if "is_active" in payload:
        user.is_active = bool(payload["is_active"])

    db.session.commit()
    return ok(user.to_dict(include_tenants=True))


@users_bp.delete("/users/<int:user_id>")
def delete_user(user_id):
    user = AppUser.query.filter(AppUser.id == user_id).first_or_404()
    db.session.delete(user)
    db.session.commit()
    return ok({"deleted": True, "id": user_id})


@users_bp.get("/user-tenants")
def list_user_tenants():
    query = UserTenant.query

    user_id = request.args.get("user_id", type=int)
    if user_id is not None:
        query = query.filter(UserTenant.user_id == user_id)

    tenant_slug = request.args.get("tenant_slug")
    if tenant_slug:
        query = query.filter(UserTenant.tenant_slug == tenant_slug.strip().lower())

    mappings = query.order_by(UserTenant.created_at.desc()).all()
    return ok({"items": [mapping.to_dict() for mapping in mappings], "access_roles": sorted(TENANT_ACCESS_ROLES)})


@users_bp.post("/user-tenants")
def create_user_tenant():
    payload = request.get_json(force=True)
    mapping = UserService.map_user_to_tenant(
        user_id=payload.get("user_id"),
        tenant_id=payload.get("tenant_id"),
        tenant_slug=payload.get("tenant_slug"),
        access_role=payload.get("access_role", "site_operations"),
        is_active=payload.get("is_active", True),
    )
    return created(mapping.to_dict())


@users_bp.patch("/user-tenants/<int:mapping_id>")
def update_user_tenant(mapping_id):
    payload = request.get_json(force=True)
    mapping = UserTenant.query.filter(UserTenant.id == mapping_id).first_or_404()

    if "access_role" in payload:
        mapping.access_role = UserService.validate_access_role(payload["access_role"])
    if "is_active" in payload:
        mapping.is_active = bool(payload["is_active"])

    db.session.commit()
    return ok(mapping.to_dict())


@users_bp.delete("/user-tenants/<int:mapping_id>")
def delete_user_tenant(mapping_id):
    mapping = UserTenant.query.filter(UserTenant.id == mapping_id).first_or_404()
    db.session.delete(mapping)
    db.session.commit()
    return ok({"deleted": True, "id": mapping_id})

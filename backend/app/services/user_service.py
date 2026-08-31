from werkzeug.security import check_password_hash, generate_password_hash

from ..extensions.database import db
from ..models.app_user import AppUser
from ..models.tenant import Tenant
from ..models.user_tenant import UserTenant


TENANT_ADMIN_ROLE = "tenant_admin"

TENANT_ACCESS_ROLES = {
    "admin",
    "tenant_admin",
    "project_management",
    "site_operations",
    "warehouse_control",
    "finance_review",
}


class UserService:
    @staticmethod
    def normalize_username(value):
        username = (value or "").strip().lower()
        if len(username) < 3:
            raise ValueError("username must be at least 3 characters")
        return username

    @staticmethod
    def normalize_email(value):
        email = (value or "").strip().lower()
        if "@" not in email or "." not in email.split("@")[-1]:
            raise ValueError("a valid email is required")
        return email

    @staticmethod
    def validate_access_role(value):
        access_role = (value or "site_operations").strip()
        if access_role not in TENANT_ACCESS_ROLES:
            raise ValueError(f"access_role must be one of: {', '.join(sorted(TENANT_ACCESS_ROLES))}")
        return access_role

    @staticmethod
    def hash_password(password):
        if not password or len(password) < 8:
            raise ValueError("password must be at least 8 characters")
        return generate_password_hash(password)

    @staticmethod
    def verify_password(user, password):
        return check_password_hash(user.password_hash, password or "")

    @staticmethod
    def create_user(username, email, full_name, password, is_active=True):
        username = UserService.normalize_username(username)
        email = UserService.normalize_email(email)
        full_name = (full_name or "").strip()
        if not full_name:
            raise ValueError("full_name is required")

        if AppUser.query.filter(AppUser.username == username).first():
            raise ValueError("username already exists")
        if AppUser.query.filter(AppUser.email == email).first():
            raise ValueError("email already exists")

        user = AppUser(
            username=username,
            email=email,
            full_name=full_name,
            password_hash=UserService.hash_password(password),
            is_active=bool(is_active),
        )
        db.session.add(user)
        db.session.commit()
        return user

    @staticmethod
    def map_user_to_tenant(user_id, tenant_id=None, tenant_slug=None, access_role="site_operations", is_active=True):
        user = AppUser.query.filter(AppUser.id == user_id).first()
        if not user:
            raise ValueError("user not found")

        tenant_query = Tenant.query
        if tenant_id is not None:
            tenant = tenant_query.filter(Tenant.id == tenant_id).first()
        else:
            tenant = tenant_query.filter(Tenant.slug == (tenant_slug or "").strip().lower()).first()
        if not tenant:
            raise ValueError("tenant not found")

        existing = UserTenant.query.filter(
            UserTenant.user_id == user.id,
            UserTenant.tenant_id == tenant.id,
        ).first()
        if existing:
            raise ValueError("user is already mapped to this tenant")

        mapping = UserTenant(
            user_id=user.id,
            tenant_id=tenant.id,
            tenant_slug=tenant.slug,
            access_role=UserService.validate_access_role(access_role),
            is_active=bool(is_active),
        )
        db.session.add(mapping)
        db.session.commit()
        return mapping

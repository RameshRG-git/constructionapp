import re

from flask import current_app, g, request
from sqlalchemy import text

from ..extensions.database import db
from ..models.tenant import Tenant


def slugify_tenant_name(value):
    normalized = (value or "").strip().lower()
    normalized = re.sub(r"[^a-z0-9]+", "_", normalized)
    normalized = re.sub(r"_+", "_", normalized).strip("_")
    if not normalized:
        raise ValueError("tenant name is required")
    return normalized


def tenant_schema_name(slug):
    return f"tenant_{slug}"


def tenant_table_prefix(slug):
    return f"{slug}_"


def resolve_tenant_name():
    requested = request.headers.get("X-Tenant") or request.args.get("tenant")
    default_tenant = current_app.config.get("DEFAULT_TENANT", "kaniskahomes")
    return slugify_tenant_name(requested or default_tenant)


def get_request_tenant_name():
    tenant_name = getattr(g, "tenant_name", None)
    if tenant_name:
        return tenant_name
    tenant_name = resolve_tenant_name()
    g.tenant_name = tenant_name
    return tenant_name


def ensure_default_tenant():
    default_tenant = slugify_tenant_name(current_app.config.get("DEFAULT_TENANT", "kaniskahomes"))
    tenant = Tenant.query.filter(Tenant.slug == default_tenant).first()
    if tenant:
        return tenant

    tenant = Tenant(
        name="KaniskaHomes",
        slug=default_tenant,
        schema_name=tenant_schema_name(default_tenant),
        table_prefix=tenant_table_prefix(default_tenant),
        primary_color="#0F4C5C",
        secondary_color="#2C7A7B",
        is_active=True,
    )
    db.session.add(tenant)
    db.session.commit()
    ensure_tenant_schema(tenant)
    return tenant


def ensure_tenant_schema(tenant):
    if not current_app.config.get("SQLALCHEMY_DATABASE_URI", "").startswith("postgresql"):
        return

    schema_name = tenant.schema_name
    db.session.execute(text(f'CREATE SCHEMA IF NOT EXISTS "{schema_name}"'))
    db.session.commit()
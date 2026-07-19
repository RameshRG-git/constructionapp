from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.tenant import Tenant
from ..services.tenancy import (
    ensure_tenant_schema,
    get_request_tenant_name,
    slugify_tenant_name,
    tenant_schema_name,
    tenant_table_prefix,
)


tenants_bp = Blueprint("tenants", __name__)


@tenants_bp.get("/tenants")
def list_tenants():
    items = Tenant.query.order_by(Tenant.created_at.desc()).all()
    return ok({"items": [item.to_dict() for item in items]})


@tenants_bp.post("/tenants")
def create_tenant():
    payload = request.get_json(force=True)
    name = payload.get("name", "").strip()
    slug = slugify_tenant_name(payload.get("slug") or name)
    schema_name = payload.get("schema_name") or tenant_schema_name(slug)
    table_prefix = payload.get("table_prefix") or tenant_table_prefix(slug)

    tenant = Tenant(
        name=name,
        slug=slug,
        schema_name=schema_name,
        table_prefix=table_prefix,
        logo_url=payload.get("logo_url"),
        primary_color=payload.get("primary_color", "#0F4C5C"),
        secondary_color=payload.get("secondary_color", "#2C7A7B"),
        is_active=bool(payload.get("is_active", True)),
    )
    db.session.add(tenant)
    db.session.commit()
    ensure_tenant_schema(tenant)
    return created(tenant.to_dict())


@tenants_bp.get("/tenants/current")
def get_current_tenant():
    tenant_name = get_request_tenant_name()
    tenant = Tenant.query.filter(Tenant.slug == tenant_name, Tenant.is_active.is_(True)).first_or_404()
    return ok(tenant.to_dict())
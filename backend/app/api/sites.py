from datetime import datetime

from flask import Blueprint, request
from sqlalchemy import asc, desc

from .response import created, ok
from ..models.site import Site
from ..services.domain_rules import SiteStatus
from ..services.site_service import SiteService
from ..services.tenancy import get_request_tenant_name


sites_bp = Blueprint("sites", __name__)


@sites_bp.get("")
def list_sites():
    tenant_name = get_request_tenant_name()
    query = Site.query.filter(Site.tenant_name == tenant_name)

    status = request.args.get("status")
    owner_name = request.args.get("owner_name")
    q = request.args.get("q")
    sort_by = request.args.get("sort_by", "created_at")
    sort_order = request.args.get("sort_order", "desc")

    if status:
        query = query.filter(Site.status == SiteStatus(status))
    if owner_name:
        query = query.filter(Site.owner_name.ilike(f"%{owner_name}%"))
    if q:
        query = query.filter(
            Site.name.ilike(f"%{q}%")
            | Site.site_location.ilike(f"%{q}%")
            | Site.owner_name.ilike(f"%{q}%")
        )

    sortable_columns = {
        "name": Site.name,
        "site_location": Site.site_location,
        "owner_name": Site.owner_name,
        "planned_start_date": Site.planned_start_date,
        "planned_end_date": Site.planned_end_date,
        "status": Site.status,
        "created_at": Site.created_at,
    }
    sort_column = sortable_columns.get(sort_by, Site.created_at)
    query = query.order_by(asc(sort_column) if sort_order == "asc" else desc(sort_column))

    sites = query.all()
    return ok({"items": [site.to_dict() for site in sites]})


@sites_bp.get("/<int:site_id>")
def get_site(site_id):
    tenant_name = get_request_tenant_name()
    site = Site.query.filter(Site.id == site_id, Site.tenant_name == tenant_name).first_or_404()
    return ok(site.to_dict())


@sites_bp.post("")
def create_site():
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    planned_start_date = datetime.fromisoformat(payload["planned_start_date"]).date()
    planned_end_date = payload.get("planned_end_date")
    site = SiteService.create_site(
        tenant_name=tenant_name,
        name=payload["name"],
        site_location=payload["site_location"],
        owner_name=payload["owner_name"],
        planned_start_date=planned_start_date,
        planned_end_date=datetime.fromisoformat(planned_end_date).date() if planned_end_date else planned_start_date,
        status=SiteStatus(payload.get("status", SiteStatus.PLANNED)),
    )
    return created(site.to_dict())


@sites_bp.patch("/<int:site_id>")
def update_site(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    site = Site.query.filter(Site.id == site_id, Site.tenant_name == tenant_name).first_or_404()
    updates = {}
    for key in ["name", "site_location", "owner_name"]:
        if key in payload:
            updates[key] = payload[key]
    if "status" in payload:
        updates["status"] = SiteStatus(payload["status"])
    if "planned_start_date" in payload:
        updates["planned_start_date"] = datetime.fromisoformat(payload["planned_start_date"]).date()
    if "planned_end_date" in payload:
        end_date = payload["planned_end_date"]
        updates["planned_end_date"] = datetime.fromisoformat(end_date).date() if end_date else site.planned_start_date
    updated = SiteService.update_site(site, **updates)
    return ok(updated.to_dict())


@sites_bp.post("/<int:site_id>/close")
def close_site(site_id):
    tenant_name = get_request_tenant_name()
    site = Site.query.filter(Site.id == site_id, Site.tenant_name == tenant_name).first_or_404()
    updated = SiteService.update_site(site, status=SiteStatus.CLOSED)
    return ok(updated.to_dict())
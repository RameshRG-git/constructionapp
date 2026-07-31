from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.team_role_rate import TeamRoleRate
from ..services.tenancy import get_request_tenant_name


team_roles_bp = Blueprint("team_roles", __name__)

DEFAULT_ROLE_RATES = [
    ("Senior Mason", 1100, 10),
    ("Junior Mason", 1000, 20),
    ("Senior Helper", 850, 30),
    ("MidLevel Helper", 800, 40),
    ("Junior Helper", 750, 50),
    ("Senior Fitter", 1300, 60),
    ("Junior Fitter", 1200, 70),
    ("Carpenter", 1000, 80),
]


def _ensure_default_roles(tenant_name):
    existing_count = TeamRoleRate.query.filter(TeamRoleRate.tenant_name == tenant_name).count()
    if existing_count > 0:
        return

    for title, pay_rate, order in DEFAULT_ROLE_RATES:
        db.session.add(
            TeamRoleRate(
                tenant_name=tenant_name,
                title=title,
                daily_pay_rate=pay_rate,
                sort_order=order,
                is_active=True,
            )
        )
    db.session.commit()


@team_roles_bp.get("/team-roles")
def list_team_roles():
    tenant_name = get_request_tenant_name()
    _ensure_default_roles(tenant_name)

    include_inactive = request.args.get("include_inactive", "false").lower() == "true"
    query = TeamRoleRate.query.filter(TeamRoleRate.tenant_name == tenant_name)
    if not include_inactive:
        query = query.filter(TeamRoleRate.is_active.is_(True))

    items = query.order_by(TeamRoleRate.sort_order.asc(), TeamRoleRate.title.asc()).all()
    return ok({"items": [item.to_dict() for item in items]})


@team_roles_bp.post("/team-roles")
def create_team_role():
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    item = TeamRoleRate(
        tenant_name=tenant_name,
        title=payload["title"].strip(),
        daily_pay_rate=payload["daily_pay_rate"],
        sort_order=payload.get("sort_order", 100),
        is_active=bool(payload.get("is_active", True)),
    )
    db.session.add(item)
    db.session.commit()
    return created(item.to_dict())


@team_roles_bp.patch("/team-roles/<int:role_id>")
def update_team_role(role_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    item = TeamRoleRate.query.filter(
        TeamRoleRate.id == role_id,
        TeamRoleRate.tenant_name == tenant_name,
    ).first_or_404()

    if "title" in payload:
        item.title = payload["title"].strip()
    if "daily_pay_rate" in payload:
        item.daily_pay_rate = payload["daily_pay_rate"]
    if "sort_order" in payload:
        item.sort_order = payload["sort_order"]
    if "is_active" in payload:
        item.is_active = bool(payload["is_active"])

    db.session.commit()
    return ok(item.to_dict())
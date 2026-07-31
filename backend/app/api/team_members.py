from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.team_member import TeamMember
from ..services.team_member_service import TeamMemberService
from ..services.tenancy import get_request_tenant_name


team_members_bp = Blueprint("team_members", __name__)


@team_members_bp.get("/team-members")
def list_team_members():
    tenant_name = get_request_tenant_name()
    query = TeamMember.query.filter(TeamMember.tenant_name == tenant_name)

    search = request.args.get("q", "").strip()
    if search:
        query = query.filter(TeamMember.full_name.ilike(f"%{search}%"))

    include_inactive = request.args.get("include_inactive", "false").lower() == "true"
    if not include_inactive:
        query = query.filter(TeamMember.is_active.is_(True))

    sort_by = request.args.get("sort_by", "full_name")
    sort_order = request.args.get("sort_order", "asc")
    sortable = {
        "full_name": TeamMember.full_name,
        "job_title": TeamMember.job_title,
        "daily_pay_rate": TeamMember.daily_pay_rate,
        "created_at": TeamMember.created_at,
    }
    sort_column = sortable.get(sort_by, TeamMember.full_name)
    if sort_order == "desc":
        sort_column = sort_column.desc()

    items = query.order_by(sort_column, TeamMember.id.desc()).all()
    return ok({"items": [item.to_dict() for item in items]})


@team_members_bp.post("/team-members")
def create_team_member():
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)

    member = TeamMemberService.create_member(
        tenant_name=tenant_name,
        full_name=payload["full_name"].strip(),
        job_title=payload["job_title"].strip(),
        daily_pay_rate=payload["daily_pay_rate"],
        app_access_planned=bool(payload.get("app_access_planned", False)),
        access_email=(payload.get("access_email") or "").strip() or None,
        access_role=(payload.get("access_role") or "worker").strip() or "worker",
        is_active=bool(payload.get("is_active", True)),
    )
    return created(member.to_dict())


@team_members_bp.patch("/team-members/<int:member_id>")
def update_team_member(member_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    member = TeamMember.query.filter(
        TeamMember.id == member_id,
        TeamMember.tenant_name == tenant_name,
    ).first_or_404()

    if "full_name" in payload:
        member.full_name = payload["full_name"].strip()
    if "job_title" in payload:
        member.job_title = payload["job_title"].strip()
    if "daily_pay_rate" in payload:
        member.daily_pay_rate = payload["daily_pay_rate"]
    if "app_access_planned" in payload:
        member.app_access_planned = bool(payload["app_access_planned"])
    if "access_email" in payload:
        member.access_email = (payload["access_email"] or "").strip() or None
    if "access_role" in payload:
        member.access_role = (payload["access_role"] or "worker").strip() or "worker"
    if "is_active" in payload:
        member.is_active = bool(payload["is_active"])

    db.session.commit()
    return ok(member.to_dict())
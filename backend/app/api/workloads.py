from datetime import date, datetime

from sqlalchemy import and_, func, or_

from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.work_assignment import WorkAssignment
from ..services.domain_rules import WorkStatus
from ..services.tenancy import get_request_tenant_name
from ..services.workload_service import WorkloadService


workloads_bp = Blueprint("workloads", __name__)


def _assignment_end_date_expr():
    return func.coalesce(WorkAssignment.week_end_date, WorkAssignment.due_date)


def _assignment_start_date_expr():
    return func.coalesce(WorkAssignment.week_start_date, WorkAssignment.due_date)


def _auto_complete_past_workloads(site_id, tenant_name):
    today = date.today()
    items = WorkAssignment.query.filter(
        WorkAssignment.site_id == site_id,
        WorkAssignment.tenant_name == tenant_name,
        WorkAssignment.status != WorkStatus.COMPLETED,
        _assignment_end_date_expr() < today,
    ).all()
    if not items:
        return
    for item in items:
        item.status = WorkStatus.COMPLETED
    db.session.commit()


@workloads_bp.get("/sites/<int:site_id>/assignments")
def list_workloads(site_id):
    tenant_name = get_request_tenant_name()
    _auto_complete_past_workloads(site_id, tenant_name)

    query = WorkAssignment.query.filter(WorkAssignment.site_id == site_id, WorkAssignment.tenant_name == tenant_name)
    status = request.args.get("status")
    assignee = request.args.get("assignee")
    search = request.args.get("q", "").strip()
    include_past = request.args.get("include_past", "false").lower() == "true"
    on_date = request.args.get("on_date")
    from_date = request.args.get("from_date")
    to_date = request.args.get("to_date")
    week_start = request.args.get("week_start")
    sort_by = request.args.get("sort_by", "due_date")
    sort_order = request.args.get("sort_order", "asc")
    has_history_query = bool(search or on_date or from_date or to_date or week_start or assignee)

    if status:
        query = query.filter(WorkAssignment.status == WorkStatus(status))
    if assignee:
        query = query.filter(WorkAssignment.assignee_name.ilike(f"%{assignee}%"))
    if search:
        query = query.filter(
            or_(
                WorkAssignment.title.ilike(f"%{search}%"),
                WorkAssignment.assignee_name.ilike(f"%{search}%"),
            )
        )

    if on_date:
        target_date = datetime.fromisoformat(on_date).date()
        query = query.filter(
            and_(
                _assignment_start_date_expr() <= target_date,
                _assignment_end_date_expr() >= target_date,
            )
        )

    if from_date:
        start = datetime.fromisoformat(from_date).date()
        query = query.filter(_assignment_end_date_expr() >= start)

    if to_date:
        end = datetime.fromisoformat(to_date).date()
        query = query.filter(_assignment_start_date_expr() <= end)

    if week_start:
        query = query.filter(WorkAssignment.week_start_date == datetime.fromisoformat(week_start).date())

    if not include_past and not has_history_query:
        query = query.filter(
            WorkAssignment.status != WorkStatus.COMPLETED,
            _assignment_end_date_expr() >= date.today(),
        )

    items = query.all()
    sortable = {
        "week_start_date": lambda assignment: assignment.week_start_date or assignment.due_date,
        "due_date": lambda assignment: assignment.due_date,
        "priority": lambda assignment: assignment.priority or "",
        "assignee_name": lambda assignment: assignment.assignee_name or "",
        "status": lambda assignment: assignment.status.value if assignment.status else "",
    }
    sort_fn = sortable.get(sort_by, sortable["due_date"])
    items = sorted(items, key=sort_fn, reverse=sort_order == "desc")
    return ok({"items": [assignment.to_dict() for assignment in items]})


@workloads_bp.post("/sites/<int:site_id>/assignments")
def create_workload(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    period_start_raw = payload.get("period_start_date") or payload.get("week_start_date") or payload.get("due_date")
    period_end_raw = payload.get("period_end_date") or payload.get("week_end_date") or period_start_raw
    week_start_date = datetime.fromisoformat(period_start_raw).date() if period_start_raw else None
    week_end_date = datetime.fromisoformat(period_end_raw).date() if period_end_raw else week_start_date
    due_date = datetime.fromisoformat(payload.get("due_date") or period_end_raw or period_start_raw).date()

    effective_status = WorkStatus(payload.get("status", WorkStatus.OPEN))
    if week_end_date and week_end_date < date.today():
        effective_status = WorkStatus.COMPLETED

    assignment = WorkloadService.create_assignment(
        tenant_name=tenant_name,
        site_id=site_id,
        assignee_type=payload["assignee_type"],
        assignee_name=payload["assignee_name"],
        title=payload["title"],
        description=payload.get("description"),
        priority=payload.get("priority", "normal"),
        status=effective_status,
        week_start_date=week_start_date,
        week_end_date=week_end_date,
        due_date=due_date,
        estimated_hours=payload.get("estimated_hours"),
        paid_amount=payload.get("paid_amount", 0),
    )
    return created(assignment.to_dict())


@workloads_bp.patch("/assignments/<int:assignment_id>")
def update_workload(assignment_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    assignment = WorkAssignment.query.filter(
        WorkAssignment.id == assignment_id,
        WorkAssignment.tenant_name == tenant_name,
    ).first_or_404()

    for key in ["assignee_type", "assignee_name", "title", "description", "priority", "paid_amount"]:
        if key in payload:
            setattr(assignment, key, payload[key])

    if "status" in payload:
        assignment.status = WorkStatus(payload["status"])
    if "due_date" in payload:
        assignment.due_date = datetime.fromisoformat(payload["due_date"]).date()
    if "week_start_date" in payload:
        assignment.week_start_date = datetime.fromisoformat(payload["week_start_date"]).date() if payload["week_start_date"] else None
    if "week_end_date" in payload:
        assignment.week_end_date = datetime.fromisoformat(payload["week_end_date"]).date() if payload["week_end_date"] else None
    if "period_start_date" in payload:
        assignment.week_start_date = datetime.fromisoformat(payload["period_start_date"]).date() if payload["period_start_date"] else None
    if "period_end_date" in payload:
        assignment.week_end_date = datetime.fromisoformat(payload["period_end_date"]).date() if payload["period_end_date"] else None
    if "estimated_hours" in payload:
        assignment.estimated_hours = payload["estimated_hours"]

    if assignment.week_start_date and not assignment.week_end_date:
        assignment.week_end_date = assignment.week_start_date
    if assignment.week_end_date and assignment.week_end_date < date.today():
        assignment.status = WorkStatus.COMPLETED

    db.session.commit()
    return ok(assignment.to_dict())

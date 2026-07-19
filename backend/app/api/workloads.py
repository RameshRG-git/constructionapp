from datetime import datetime

from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.work_assignment import WorkAssignment
from ..services.domain_rules import WorkStatus
from ..services.tenancy import get_request_tenant_name
from ..services.workload_service import WorkloadService


workloads_bp = Blueprint("workloads", __name__)


@workloads_bp.get("/sites/<int:site_id>/assignments")
def list_workloads(site_id):
    tenant_name = get_request_tenant_name()
    query = WorkAssignment.query.filter(WorkAssignment.site_id == site_id, WorkAssignment.tenant_name == tenant_name)
    status = request.args.get("status")
    assignee = request.args.get("assignee")
    sort_by = request.args.get("sort_by", "due_date")
    sort_order = request.args.get("sort_order", "asc")

    if status:
        query = query.filter(WorkAssignment.status == WorkStatus(status))
    if assignee:
        query = query.filter(WorkAssignment.assignee_name.ilike(f"%{assignee}%"))

    items = query.all()
    sortable = {
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
    assignment = WorkloadService.create_assignment(
        tenant_name=tenant_name,
        site_id=site_id,
        assignee_type=payload["assignee_type"],
        assignee_name=payload["assignee_name"],
        title=payload["title"],
        description=payload.get("description"),
        priority=payload.get("priority", "normal"),
        status=WorkStatus(payload.get("status", WorkStatus.OPEN)),
        due_date=datetime.fromisoformat(payload["due_date"]).date(),
        estimated_hours=payload.get("estimated_hours"),
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

    for key in ["assignee_type", "assignee_name", "title", "description", "priority"]:
        if key in payload:
            setattr(assignment, key, payload[key])

    if "status" in payload:
        assignment.status = WorkStatus(payload["status"])
    if "due_date" in payload:
        assignment.due_date = datetime.fromisoformat(payload["due_date"]).date()
    if "estimated_hours" in payload:
        assignment.estimated_hours = payload["estimated_hours"]

    db.session.commit()
    return ok(assignment.to_dict())

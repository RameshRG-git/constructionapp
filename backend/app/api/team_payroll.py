from datetime import datetime

from flask import Blueprint, abort, request

from .response import created, ok
from ..extensions.database import db
from ..models.advance_recovery import AdvanceRecovery
from ..models.employee_advance import EmployeeAdvance
from ..models.sick_leave import SickLeave
from ..models.team_member import TeamMember
from ..services.advance_service import AdvanceService
from ..services.sick_leave_service import SickLeaveService
from ..services.tenancy import get_request_tenant_name


team_payroll_bp = Blueprint("team_payroll", __name__)


@team_payroll_bp.get("/team/sick-leaves")
def list_sick_leaves():
    tenant_name = get_request_tenant_name()
    query = SickLeave.query.filter(SickLeave.tenant_name == tenant_name)

    employee = request.args.get("employee_name", "").strip()
    if employee:
        query = query.filter(SickLeave.employee_name.ilike(f"%{employee}%"))

    items = query.order_by(SickLeave.start_date.desc(), SickLeave.id.desc()).all()
    return ok({"items": [item.to_dict() for item in items]})


@team_payroll_bp.post("/team/sick-leaves")
def create_sick_leave():
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    member = TeamMember.query.filter(
        TeamMember.id == payload.get("team_member_id"),
        TeamMember.tenant_name == tenant_name,
    ).first()
    if member is None:
        abort(400, "A valid team_member_id is required")

    start_date = datetime.fromisoformat(payload["start_date"]).date()
    end_date = datetime.fromisoformat(payload.get("end_date") or payload["start_date"]).date()
    if end_date < start_date:
        abort(400, "end_date cannot be before start_date")

    leave = SickLeaveService.create(
        tenant_name=tenant_name,
        team_member_id=member.id,
        employee_name=member.full_name,
        start_date=start_date,
        end_date=end_date,
        reason=payload.get("reason"),
    )
    return created(leave.to_dict())


@team_payroll_bp.delete("/team/sick-leaves/<int:leave_id>")
def delete_sick_leave(leave_id):
    tenant_name = get_request_tenant_name()
    leave = SickLeave.query.filter(
        SickLeave.id == leave_id,
        SickLeave.tenant_name == tenant_name,
    ).first_or_404()
    SickLeaveService.delete(leave)
    return ok({"deleted": True, "id": leave_id})


@team_payroll_bp.get("/team/advances")
def list_advances():
    tenant_name = get_request_tenant_name()
    query = EmployeeAdvance.query.filter(EmployeeAdvance.tenant_name == tenant_name)

    employee = request.args.get("employee_name", "").strip()
    if employee:
        query = query.filter(EmployeeAdvance.employee_name.ilike(f"%{employee}%"))

    status = request.args.get("status")
    items = [item.to_dict() for item in query.order_by(EmployeeAdvance.due_date.asc(), EmployeeAdvance.id.desc()).all()]
    if status:
        items = [item for item in items if item["status"] == status]

    return ok({"items": items})


@team_payroll_bp.post("/team/advances")
def create_advance():
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    member = TeamMember.query.filter(
        TeamMember.id == payload.get("team_member_id"),
        TeamMember.tenant_name == tenant_name,
    ).first()
    if member is None:
        abort(400, "A valid team_member_id is required")
    if not payload.get("due_date"):
        abort(400, "due_date is required")

    advance = AdvanceService.create(
        tenant_name=tenant_name,
        team_member_id=member.id,
        employee_name=member.full_name,
        amount=payload["amount"],
        granted_on=datetime.fromisoformat(payload["granted_on"]).date() if payload.get("granted_on") else datetime.utcnow().date(),
        due_date=datetime.fromisoformat(payload["due_date"]).date(),
        note=payload.get("note"),
    )
    return created(advance.to_dict())


@team_payroll_bp.patch("/team/advances/<int:advance_id>")
def update_advance(advance_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    advance = EmployeeAdvance.query.filter(
        EmployeeAdvance.id == advance_id,
        EmployeeAdvance.tenant_name == tenant_name,
    ).first_or_404()

    if "amount" in payload:
        advance.amount = payload["amount"]
    if "due_date" in payload:
        advance.due_date = datetime.fromisoformat(payload["due_date"]).date()
    if "note" in payload:
        advance.note = payload["note"]

    db.session.commit()
    return ok(advance.to_dict())


@team_payroll_bp.delete("/team/advances/<int:advance_id>")
def delete_advance(advance_id):
    tenant_name = get_request_tenant_name()
    advance = EmployeeAdvance.query.filter(
        EmployeeAdvance.id == advance_id,
        EmployeeAdvance.tenant_name == tenant_name,
    ).first_or_404()
    AdvanceRecovery.query.filter(AdvanceRecovery.advance_id == advance.id).delete()
    AdvanceService.delete(advance)
    return ok({"deleted": True, "id": advance_id})


@team_payroll_bp.get("/team/advances/<int:advance_id>/recoveries")
def list_advance_recoveries(advance_id):
    tenant_name = get_request_tenant_name()
    recoveries = AdvanceRecovery.query.filter(
        AdvanceRecovery.advance_id == advance_id,
        AdvanceRecovery.tenant_name == tenant_name,
    ).order_by(AdvanceRecovery.week_start_date.asc()).all()
    return ok({"items": [item.to_dict() for item in recoveries]})

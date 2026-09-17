from datetime import date, datetime

from flask import Blueprint, abort, request

from .response import ok
from ..extensions.database import db
from ..services.payroll_service import PayrollService, current_week_start, parse_week_start
from ..services.tenancy import get_request_tenant_name


payroll_bp = Blueprint("payroll", __name__)


def _parse_optional_date(value):
    return datetime.fromisoformat(value).date() if value else None


@payroll_bp.get("/sites/<int:site_id>/payroll")
def get_site_payroll(site_id):
    tenant_name = get_request_tenant_name()
    week_start = parse_week_start(request.args.get("week_start"))
    return ok(PayrollService.week_payroll(tenant_name, site_id, week_start))


@payroll_bp.get("/sites/<int:site_id>/payroll/weeks")
def list_payroll_weeks(site_id):
    tenant_name = get_request_tenant_name()
    return ok(
        {
            "current_week_start": current_week_start().isoformat(),
            "items": PayrollService.available_weeks(tenant_name, site_id),
        }
    )


@payroll_bp.post("/sites/<int:site_id>/payroll/payments")
def record_payroll_payment(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    team_member_id = payload.get("team_member_id")
    if not isinstance(team_member_id, int):
        abort(400, "team_member_id is required")

    week_start = parse_week_start(payload.get("week_start"))
    snapshot = PayrollService.week_payroll(tenant_name, site_id, week_start)
    row = next(
        (item for item in snapshot["items"] if item["team_member_id"] == team_member_id),
        None,
    )
    if row is None:
        abort(400, "No payroll workload exists for this team member and week")
    employee_name = row["employee_name"]

    earned = float(payload.get("earned_amount", row["earned_amount"] if row else 0))
    default_pay = row["net_payable_amount"] if row else earned
    paid_amount = float(payload.get("paid_amount", default_pay))
    if "status" in payload and payload["status"]:
        status = payload["status"]
    elif paid_amount >= default_pay:
        # Also covers the case where advance recovery already absorbed the full net payable.
        status = "paid"
    elif paid_amount > 0:
        status = "partial"
    else:
        status = "pending"

    PayrollService.record_payment(
        tenant_name,
        site_id,
        week_start,
        team_member_id,
        employee_name,
        earned_amount=earned,
        role_title=payload.get("role_title") or (row["role_title"] if row else None),
        days_worked=payload.get("days_worked", row["days_worked"] if row else 0),
        paid_amount=paid_amount,
        status=status,
        payment_method=payload.get("payment_method"),
        note=payload.get("note"),
        paid_on=_parse_optional_date(payload.get("paid_on")) or (date.today() if paid_amount > 0 else None),
    )
    db.session.commit()
    return ok(PayrollService.week_payroll(tenant_name, site_id, week_start))


@payroll_bp.post("/sites/<int:site_id>/payroll/pay-all")
def pay_all_payroll(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(silent=True) or {}
    week_start = parse_week_start(payload.get("week_start"))
    payment_method = payload.get("payment_method")
    paid_on = _parse_optional_date(payload.get("paid_on")) or date.today()

    snapshot = PayrollService.week_payroll(tenant_name, site_id, week_start)
    for row in snapshot["items"]:
        is_new = row["payment_id"] is None
        if is_new and row["earned_amount"] <= 0:
            continue  # nothing worked this week, nothing to settle
        if not is_new and row["outstanding_amount"] <= 0:
            continue  # already fully paid
        PayrollService.record_payment(
            tenant_name,
            site_id,
            week_start,
            row["team_member_id"],
            row["employee_name"],
            earned_amount=row["earned_amount"],
            role_title=row["role_title"],
            days_worked=row["days_worked"],
            paid_amount=row["net_payable_amount"],
            status="paid",
            payment_method=payment_method,
            paid_on=paid_on,
        )
    db.session.commit()
    return ok(PayrollService.week_payroll(tenant_name, site_id, week_start))

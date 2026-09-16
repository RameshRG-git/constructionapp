"""Weekly payroll derived from work assignments.

The payroll cycle runs Sunday -> Saturday. Amounts come from the work assignment
records (each carries the labour cost for its own period), pro-rated by day so an
assignment that spans two weeks only contributes the days that fall in the week
being viewed. Sick-leave days are excluded from pay day-by-day, and any employee
advance that has come due is recovered (FIFO by due date) from that week's net pay,
carrying forward automatically if the advance is larger than the week's earnings.
"""

from datetime import date, datetime, timedelta

from ..extensions.database import db
from ..models.payroll_payment import PayrollPayment
from ..models.team_member import TeamMember
from ..models.work_assignment import WorkAssignment
from .advance_service import AdvanceService
from .sick_leave_service import SickLeaveService

PAYROLL_WEEK_LENGTH = 7


def week_start_for(day):
    """Return the Sunday that starts the payroll week containing ``day``."""
    return day - timedelta(days=(day.weekday() + 1) % PAYROLL_WEEK_LENGTH)


def week_end_for(day):
    return week_start_for(day) + timedelta(days=PAYROLL_WEEK_LENGTH - 1)


def current_week_start():
    return week_start_for(date.today())


def parse_week_start(value):
    """Normalise any date inside a week to that week's Sunday."""
    if not value:
        return current_week_start()
    return week_start_for(datetime.fromisoformat(value).date())


def _assignment_period(assignment):
    start = assignment.week_start_date or assignment.due_date
    end = assignment.week_end_date or assignment.due_date or start
    if end < start:
        end = start
    return start, end


def _overlap_date_list(start, end, window_start, window_end):
    first = max(start, window_start)
    last = min(end, window_end)
    if last < first:
        return []
    dates = []
    cursor = first
    while cursor <= last:
        dates.append(cursor)
        cursor += timedelta(days=1)
    return dates


class PayrollService:
    @staticmethod
    def week_payroll(tenant_name, site_id, week_start):
        week_end = week_start + timedelta(days=PAYROLL_WEEK_LENGTH - 1)

        assignments = WorkAssignment.query.filter(
            WorkAssignment.site_id == site_id,
            WorkAssignment.tenant_name == tenant_name,
        ).all()

        member_rates = {
            member.full_name.strip().lower(): float(member.daily_pay_rate or 0)
            for member in TeamMember.query.filter(TeamMember.tenant_name == tenant_name).all()
        }

        # Pass 1: gather each assignment's overlap dates per employee, before sick-leave exclusion.
        rows = {}
        for assignment in assignments:
            start, end = _assignment_period(assignment)
            if not start or not end:
                continue
            overlap_dates = _overlap_date_list(start, end, week_start, week_end)
            if not overlap_dates:
                continue

            total_days = (end - start).days + 1
            per_day_amount = float(assignment.paid_amount or 0) / total_days
            per_day_hours = float(assignment.estimated_hours or 0)

            employee_name = (assignment.assignee_name or "Unassigned").strip()
            key = employee_name.lower()
            row = rows.setdefault(
                key,
                {
                    "employee_name": employee_name,
                    "role_title": assignment.assignee_type,
                    "raw_assignments": [],
                },
            )
            row["raw_assignments"].append(
                {
                    "assignment": assignment,
                    "dates": overlap_dates,
                    "per_day_amount": per_day_amount,
                    "per_day_hours": per_day_hours,
                }
            )

        payments = {
            payment.employee_name.strip().lower(): payment
            for payment in PayrollPayment.query.filter(
                PayrollPayment.tenant_name == tenant_name,
                PayrollPayment.site_id == site_id,
                PayrollPayment.week_start_date == week_start,
            ).all()
        }

        items = []
        for key, row in rows.items():
            employee_name = row["employee_name"]
            sick_dates = SickLeaveService.sick_dates_for_employee(tenant_name, employee_name, week_start, week_end)

            days_worked = 0
            sick_days = 0
            hours_worked = 0.0
            earned_amount = 0.0
            assignment_details = []

            for entry in row["raw_assignments"]:
                assignment = entry["assignment"]
                worked_dates = [d for d in entry["dates"] if d not in sick_dates]
                sick_in_assignment = len(entry["dates"]) - len(worked_dates)
                amount = entry["per_day_amount"] * len(worked_dates)

                days_worked += len(worked_dates)
                sick_days += sick_in_assignment
                hours_worked += entry["per_day_hours"] * len(worked_dates)
                earned_amount += amount

                assignment_details.append(
                    {
                        "id": assignment.id,
                        "title": assignment.title,
                        "status": assignment.status.value if assignment.status else None,
                        "start_date": entry["dates"][0].isoformat(),
                        "end_date": entry["dates"][-1].isoformat(),
                        "days_in_week": len(worked_dates),
                        "sick_days_excluded": sick_in_assignment,
                        "amount": round(amount, 2),
                    }
                )

            earned = round(earned_amount, 2)
            payment = payments.get(key)
            paid = round(float(payment.paid_amount or 0), 2) if payment else 0.0
            status = payment.status if payment else "pending"
            daily_rate = member_rates.get(key)
            if daily_rate is None and days_worked:
                daily_rate = round(earned / days_worked, 2)

            if payment is not None:
                # Recovery is locked in once a payment record exists for this week.
                advance_recovery_amount = round(float(payment.advance_recovery_amount or 0), 2)
            else:
                advance_recovery_amount = AdvanceService.preview_recovery(tenant_name, employee_name, week_end, earned)
            net_payable_amount = round(earned - advance_recovery_amount, 2)

            items.append(
                {
                    "employee_name": employee_name,
                    "role_title": row["role_title"],
                    "days_worked": days_worked,
                    "sick_days": sick_days,
                    "hours_worked": round(hours_worked, 2),
                    "daily_rate": round(daily_rate or 0, 2),
                    "earned_amount": earned,
                    "advance_recovery_amount": advance_recovery_amount,
                    "advance_balance": AdvanceService.outstanding_balance(tenant_name, employee_name),
                    "net_payable_amount": net_payable_amount,
                    "paid_amount": paid,
                    "outstanding_amount": round(net_payable_amount - paid, 2),
                    "status": status,
                    "payment_method": payment.payment_method if payment else None,
                    "note": payment.note if payment else None,
                    "paid_on": payment.paid_on.isoformat() if payment and payment.paid_on else None,
                    "payment_id": payment.id if payment else None,
                    "assignments": sorted(assignment_details, key=lambda item: item["start_date"]),
                }
            )

        items.sort(key=lambda item: item["employee_name"].lower())

        total_earned = round(sum(item["earned_amount"] for item in items), 2)
        total_paid = round(sum(item["paid_amount"] for item in items), 2)
        total_advance_recovered = round(sum(item["advance_recovery_amount"] for item in items), 2)
        total_net_payable = round(sum(item["net_payable_amount"] for item in items), 2)

        return {
            "week": {
                "week_start_date": week_start.isoformat(),
                "week_end_date": week_end.isoformat(),
                "is_current_week": week_start == current_week_start(),
                "label": f"{week_start.isoformat()} - {week_end.isoformat()}",
            },
            "items": items,
            "summary": {
                "employee_count": len(items),
                "total_days": sum(item["days_worked"] for item in items),
                "total_sick_days": sum(item["sick_days"] for item in items),
                "total_hours": round(sum(item["hours_worked"] for item in items), 2),
                "total_earned": total_earned,
                "total_advance_recovered": total_advance_recovered,
                "total_net_payable": total_net_payable,
                "total_paid": total_paid,
                "total_outstanding": round(total_net_payable - total_paid, 2),
                "paid_count": sum(1 for item in items if item["status"] == "paid"),
                "pending_count": sum(1 for item in items if item["status"] != "paid"),
            },
        }

    @staticmethod
    def available_weeks(tenant_name, site_id, limit=52):
        """Payroll weeks that have workload activity, newest first."""
        assignments = WorkAssignment.query.filter(
            WorkAssignment.site_id == site_id,
            WorkAssignment.tenant_name == tenant_name,
        ).all()

        starts = set()
        for assignment in assignments:
            start, end = _assignment_period(assignment)
            if not start or not end:
                continue
            cursor = week_start_for(start)
            while cursor <= end:
                starts.add(cursor)
                cursor += timedelta(days=PAYROLL_WEEK_LENGTH)

        starts.add(current_week_start())
        ordered = sorted(starts, reverse=True)[:limit]
        return [
            {
                "week_start_date": week.isoformat(),
                "week_end_date": (week + timedelta(days=PAYROLL_WEEK_LENGTH - 1)).isoformat(),
                "is_current_week": week == current_week_start(),
            }
            for week in ordered
        ]

    @staticmethod
    def upsert_payment(tenant_name, site_id, week_start, employee_name, **fields):
        week_end = week_start + timedelta(days=PAYROLL_WEEK_LENGTH - 1)
        payment = PayrollPayment.query.filter(
            PayrollPayment.tenant_name == tenant_name,
            PayrollPayment.site_id == site_id,
            PayrollPayment.week_start_date == week_start,
            PayrollPayment.employee_name == employee_name,
        ).first()

        if payment is None:
            payment = PayrollPayment(
                tenant_name=tenant_name,
                site_id=site_id,
                week_start_date=week_start,
                week_end_date=week_end,
                employee_name=employee_name,
            )
            db.session.add(payment)

        payment.week_end_date = week_end
        for key, value in fields.items():
            if value is not None:
                setattr(payment, key, value)
        return payment

    @staticmethod
    def record_payment(tenant_name, site_id, week_start, employee_name, earned_amount, **fields):
        """Create or update a week's payment. Advance recovery is only committed on first creation."""
        week_end = week_start + timedelta(days=PAYROLL_WEEK_LENGTH - 1)
        existing = PayrollPayment.query.filter(
            PayrollPayment.tenant_name == tenant_name,
            PayrollPayment.site_id == site_id,
            PayrollPayment.week_start_date == week_start,
            PayrollPayment.employee_name == employee_name,
        ).first()

        if existing is None:
            advance_recovery_amount = AdvanceService.apply_recovery(
                tenant_name, employee_name, week_start, week_end, earned_amount
            )
        else:
            advance_recovery_amount = float(existing.advance_recovery_amount or 0)

        payment = PayrollService.upsert_payment(
            tenant_name,
            site_id,
            week_start,
            employee_name,
            earned_amount=earned_amount,
            advance_recovery_amount=advance_recovery_amount,
            **fields,
        )
        return payment

"""Weekly payroll derived from work assignments.

The payroll cycle runs Sunday -> Saturday. Amounts come from the work assignment
records (each carries the labour cost for its own period), pro-rated by day so an
assignment that spans two weeks only contributes the days that fall in the week
being viewed.
"""

from datetime import date, datetime, timedelta

from ..extensions.database import db
from ..models.payroll_payment import PayrollPayment
from ..models.team_member import TeamMember
from ..models.work_assignment import WorkAssignment

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


def _overlap_days(start, end, window_start, window_end):
    first = max(start, window_start)
    last = min(end, window_end)
    if last < first:
        return 0
    return (last - first).days + 1


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

        rows = {}
        for assignment in assignments:
            start, end = _assignment_period(assignment)
            if not start or not end:
                continue
            days_in_week = _overlap_days(start, end, week_start, week_end)
            if days_in_week <= 0:
                continue

            total_days = (end - start).days + 1
            amount = float(assignment.paid_amount or 0) * days_in_week / total_days
            hours = float(assignment.estimated_hours or 0) * days_in_week

            employee_name = (assignment.assignee_name or "Unassigned").strip()
            key = employee_name.lower()
            row = rows.setdefault(
                key,
                {
                    "employee_name": employee_name,
                    "role_title": assignment.assignee_type,
                    "days_worked": 0,
                    "hours_worked": 0.0,
                    "earned_amount": 0.0,
                    "assignments": [],
                },
            )
            row["days_worked"] += days_in_week
            row["hours_worked"] += hours
            row["earned_amount"] += amount
            row["assignments"].append(
                {
                    "id": assignment.id,
                    "title": assignment.title,
                    "status": assignment.status.value if assignment.status else None,
                    "start_date": start.isoformat(),
                    "end_date": end.isoformat(),
                    "days_in_week": days_in_week,
                    "amount": round(amount, 2),
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
            earned = round(row["earned_amount"], 2)
            payment = payments.get(key)
            paid = round(float(payment.paid_amount or 0), 2) if payment else 0.0
            status = payment.status if payment else "pending"
            daily_rate = member_rates.get(key)
            if daily_rate is None and row["days_worked"]:
                daily_rate = round(earned / row["days_worked"], 2)

            items.append(
                {
                    "employee_name": row["employee_name"],
                    "role_title": row["role_title"],
                    "days_worked": row["days_worked"],
                    "hours_worked": round(row["hours_worked"], 2),
                    "daily_rate": round(daily_rate or 0, 2),
                    "earned_amount": earned,
                    "paid_amount": paid,
                    "outstanding_amount": round(earned - paid, 2),
                    "status": status,
                    "payment_method": payment.payment_method if payment else None,
                    "note": payment.note if payment else None,
                    "paid_on": payment.paid_on.isoformat() if payment and payment.paid_on else None,
                    "payment_id": payment.id if payment else None,
                    "assignments": sorted(row["assignments"], key=lambda item: item["start_date"]),
                }
            )

        items.sort(key=lambda item: item["employee_name"].lower())

        total_earned = round(sum(item["earned_amount"] for item in items), 2)
        total_paid = round(sum(item["paid_amount"] for item in items), 2)

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
                "total_hours": round(sum(item["hours_worked"] for item in items), 2),
                "total_earned": total_earned,
                "total_paid": total_paid,
                "total_outstanding": round(total_earned - total_paid, 2),
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

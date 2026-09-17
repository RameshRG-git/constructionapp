from ..extensions.database import db
from ..models.advance_recovery import AdvanceRecovery
from ..models.employee_advance import EmployeeAdvance


class AdvanceService:
    @staticmethod
    def create(**fields):
        advance = EmployeeAdvance(**fields)
        db.session.add(advance)
        db.session.commit()
        return advance

    @staticmethod
    def delete(advance):
        db.session.delete(advance)
        db.session.commit()

    @staticmethod
    def due_outstanding_advances(tenant_name, team_member_id, as_of_date):
        """Advances due on/before as_of_date with a remaining balance, oldest due first."""
        advances = EmployeeAdvance.query.filter(
            EmployeeAdvance.tenant_name == tenant_name,
            EmployeeAdvance.team_member_id == team_member_id,
            EmployeeAdvance.due_date <= as_of_date,
        ).order_by(EmployeeAdvance.due_date.asc(), EmployeeAdvance.id.asc()).all()
        return [advance for advance in advances if advance.outstanding_balance > 0]

    @staticmethod
    def outstanding_balance(tenant_name, team_member_id):
        advances = EmployeeAdvance.query.filter(
            EmployeeAdvance.tenant_name == tenant_name,
            EmployeeAdvance.team_member_id == team_member_id,
        ).all()
        return round(sum(advance.outstanding_balance for advance in advances), 2)

    @staticmethod
    def preview_recovery(tenant_name, team_member_id, week_end_date, net_earned):
        """Non-committing projection of how much would be recovered this week."""
        remaining = float(net_earned or 0)
        total = 0.0
        for advance in AdvanceService.due_outstanding_advances(tenant_name, team_member_id, week_end_date):
            if remaining <= 0:
                break
            take = min(advance.outstanding_balance, remaining)
            total += take
            remaining -= take
        return round(total, 2)

    @staticmethod
    def apply_recovery(tenant_name, team_member_id, employee_name, week_start_date, week_end_date, net_earned):
        """Commit recovery against outstanding advances (FIFO by due date). Returns total recovered."""
        remaining = float(net_earned or 0)
        total = 0.0
        for advance in AdvanceService.due_outstanding_advances(tenant_name, team_member_id, week_end_date):
            if remaining <= 0:
                break
            take = round(min(advance.outstanding_balance, remaining), 2)
            if take <= 0:
                continue
            advance.amount_recovered = float(advance.amount_recovered or 0) + take
            db.session.add(
                AdvanceRecovery(
                    tenant_name=tenant_name,
                    advance_id=advance.id,
                    team_member_id=team_member_id,
                    employee_name=employee_name,
                    week_start_date=week_start_date,
                    amount=take,
                )
            )
            total += take
            remaining -= take
        return round(total, 2)

    @staticmethod
    def recovery_already_recorded(tenant_name, team_member_id, week_start_date):
        existing = AdvanceRecovery.query.filter(
            AdvanceRecovery.tenant_name == tenant_name,
            AdvanceRecovery.team_member_id == team_member_id,
            AdvanceRecovery.week_start_date == week_start_date,
        ).first()
        return existing is not None

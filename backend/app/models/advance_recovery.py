from datetime import datetime

from ..extensions.database import db


class AdvanceRecovery(db.Model):
    """Ledger entry: amount recovered from one advance during one payroll week.

    Written once, when a payroll payment is first recorded for that employee/week,
    so re-viewing or re-editing that week's payment never double-deducts.
    """

    __tablename__ = "advance_recoveries"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    advance_id = db.Column(db.Integer, db.ForeignKey("employee_advances.id"), nullable=False)
    team_member_id = db.Column(db.Integer, db.ForeignKey("team_members.id"), nullable=False, index=True)
    employee_name = db.Column(db.String(255), nullable=False, index=True)
    week_start_date = db.Column(db.Date, nullable=False, index=True)
    amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "advance_id": self.advance_id,
            "team_member_id": self.team_member_id,
            "employee_name": self.employee_name,
            "week_start_date": self.week_start_date.isoformat() if self.week_start_date else None,
            "amount": float(self.amount or 0),
        }

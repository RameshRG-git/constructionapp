from datetime import datetime

from ..extensions.database import db


class EmployeeAdvance(db.Model):
    """An advance/loan given to an employee, recovered from future weekly pay once due."""

    __tablename__ = "employee_advances"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    employee_name = db.Column(db.String(255), nullable=False, index=True)
    amount = db.Column(db.Numeric(12, 2), nullable=False)
    amount_recovered = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    granted_on = db.Column(db.Date, nullable=False, default=datetime.utcnow)
    due_date = db.Column(db.Date, nullable=False)
    note = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    @property
    def outstanding_balance(self):
        return float(self.amount or 0) - float(self.amount_recovered or 0)

    @property
    def status(self):
        return "settled" if self.outstanding_balance <= 0 else "outstanding"

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "employee_name": self.employee_name,
            "amount": float(self.amount or 0),
            "amount_recovered": float(self.amount_recovered or 0),
            "outstanding_balance": round(self.outstanding_balance, 2),
            "granted_on": self.granted_on.isoformat() if self.granted_on else None,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "note": self.note,
            "status": self.status,
        }

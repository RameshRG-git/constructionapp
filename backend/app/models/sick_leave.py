from datetime import datetime

from ..extensions.database import db


class SickLeave(db.Model):
    """A logged sick-leave date range for an employee, tenant-wide (not site scoped)."""

    __tablename__ = "sick_leaves"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    employee_name = db.Column(db.String(255), nullable=False, index=True)
    start_date = db.Column(db.Date, nullable=False)
    end_date = db.Column(db.Date, nullable=False)
    reason = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "employee_name": self.employee_name,
            "start_date": self.start_date.isoformat() if self.start_date else None,
            "end_date": self.end_date.isoformat() if self.end_date else None,
            "reason": self.reason,
        }

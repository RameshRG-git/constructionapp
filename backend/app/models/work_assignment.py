from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import WorkStatus


class WorkAssignment(db.Model):
    __tablename__ = "work_assignments"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    site_id = db.Column(db.Integer, db.ForeignKey("sites.id"), nullable=False)
    assignee_type = db.Column(db.String(40), nullable=False)
    assignee_name = db.Column(db.String(255), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    priority = db.Column(db.String(40), nullable=False, default="normal")
    status = db.Column(db.Enum(WorkStatus), nullable=False, default=WorkStatus.OPEN)
    week_start_date = db.Column(db.Date, nullable=True)
    week_end_date = db.Column(db.Date, nullable=True)
    due_date = db.Column(db.Date, nullable=False)
    estimated_hours = db.Column(db.Numeric(8, 2), nullable=True)
    paid_amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "site_id": self.site_id,
            "assignee_type": self.assignee_type,
            "assignee_name": self.assignee_name,
            "title": self.title,
            "description": self.description,
            "priority": self.priority,
            "status": self.status.value if self.status else None,
            "week_start_date": self.week_start_date.isoformat() if self.week_start_date else None,
            "week_end_date": self.week_end_date.isoformat() if self.week_end_date else None,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "estimated_hours": float(self.estimated_hours or 0),
            "paid_amount": float(self.paid_amount or 0),
        }

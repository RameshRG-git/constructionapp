from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import WorkStatus


class WorkAssignment(db.Model):
    __tablename__ = "work_assignments"

    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey("projects.id"), nullable=False)
    assignee_type = db.Column(db.String(40), nullable=False)
    assignee_name = db.Column(db.String(255), nullable=False)
    title = db.Column(db.String(255), nullable=False)
    description = db.Column(db.Text, nullable=True)
    priority = db.Column(db.String(40), nullable=False, default="normal")
    status = db.Column(db.Enum(WorkStatus), nullable=False, default=WorkStatus.OPEN)
    due_date = db.Column(db.Date, nullable=False)
    estimated_hours = db.Column(db.Numeric(8, 2), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "project_id": self.project_id,
            "assignee_type": self.assignee_type,
            "assignee_name": self.assignee_name,
            "title": self.title,
            "description": self.description,
            "priority": self.priority,
            "status": self.status.value if self.status else None,
            "due_date": self.due_date.isoformat() if self.due_date else None,
            "estimated_hours": float(self.estimated_hours or 0),
        }

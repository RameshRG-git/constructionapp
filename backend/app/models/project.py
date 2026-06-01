from datetime import date, datetime

from ..extensions.database import db
from ..services.domain_rules import ProjectStatus


class Project(db.Model):
    __tablename__ = "projects"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(255), nullable=False, unique=True)
    site_location = db.Column(db.String(255), nullable=False)
    owner_name = db.Column(db.String(255), nullable=False)
    planned_start_date = db.Column(db.Date, nullable=False)
    planned_end_date = db.Column(db.Date, nullable=False)
    status = db.Column(db.Enum(ProjectStatus), nullable=False, default=ProjectStatus.PLANNED)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "site_location": self.site_location,
            "owner_name": self.owner_name,
            "planned_start_date": self.planned_start_date.isoformat() if self.planned_start_date else None,
            "planned_end_date": self.planned_end_date.isoformat() if self.planned_end_date else None,
            "status": self.status.value if self.status else None,
        }

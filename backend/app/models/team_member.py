from datetime import datetime

from ..extensions.database import db


class TeamMember(db.Model):
    __tablename__ = "team_members"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    full_name = db.Column(db.String(255), nullable=False)
    job_title = db.Column(db.String(120), nullable=False)
    daily_pay_rate = db.Column(db.Numeric(10, 2), nullable=False)
    app_access_planned = db.Column(db.Boolean, nullable=False, default=False)
    access_email = db.Column(db.String(255), nullable=True)
    access_role = db.Column(db.String(40), nullable=False, default="worker")
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "full_name": self.full_name,
            "job_title": self.job_title,
            "daily_pay_rate": float(self.daily_pay_rate or 0),
            "app_access_planned": self.app_access_planned,
            "access_email": self.access_email,
            "access_role": self.access_role,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
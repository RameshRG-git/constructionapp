from datetime import datetime

from ..extensions.database import db


class TeamRoleRate(db.Model):
    __tablename__ = "team_role_rates"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    title = db.Column(db.String(120), nullable=False)
    daily_pay_rate = db.Column(db.Numeric(10, 2), nullable=False)
    sort_order = db.Column(db.Integer, nullable=False, default=100)
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (db.UniqueConstraint("tenant_name", "title", name="uq_team_role_rates_tenant_title"),)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "title": self.title,
            "daily_pay_rate": float(self.daily_pay_rate or 0),
            "sort_order": self.sort_order,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
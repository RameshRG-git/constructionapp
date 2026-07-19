from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import SiteStatus


class Site(db.Model):
    __tablename__ = "sites"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    name = db.Column(db.String(255), nullable=False)
    site_location = db.Column(db.String(255), nullable=False)
    owner_name = db.Column(db.String(255), nullable=False)
    planned_start_date = db.Column(db.Date, nullable=False)
    planned_end_date = db.Column(db.Date, nullable=False)
    status = db.Column(db.Enum(SiteStatus), nullable=False, default=SiteStatus.PLANNED)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (db.UniqueConstraint("tenant_name", "name", name="uq_sites_tenant_name"),)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "name": self.name,
            "site_location": self.site_location,
            "owner_name": self.owner_name,
            "planned_start_date": self.planned_start_date.isoformat() if self.planned_start_date else None,
            "planned_end_date": self.planned_end_date.isoformat() if self.planned_end_date else None,
            "status": self.status.value if self.status else None,
        }
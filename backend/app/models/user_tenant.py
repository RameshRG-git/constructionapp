from datetime import datetime

from ..extensions.database import db


class UserTenant(db.Model):
    __tablename__ = "user_tenants"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("app_users.id", ondelete="CASCADE"), nullable=False, index=True)
    tenant_id = db.Column(db.Integer, db.ForeignKey("tenants.id", ondelete="CASCADE"), nullable=False, index=True)
    tenant_slug = db.Column(db.String(120), nullable=False, index=True)
    access_role = db.Column(db.String(40), nullable=False, default="site_operations")
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    user = db.relationship("AppUser", back_populates="tenant_links")
    tenant = db.relationship("Tenant")

    __table_args__ = (db.UniqueConstraint("user_id", "tenant_id", name="uq_user_tenants_user_tenant"),)

    def to_dict(self):
        return {
            "id": self.id,
            "user_id": self.user_id,
            "tenant_id": self.tenant_id,
            "tenant_slug": self.tenant_slug,
            "tenant_name": self.tenant.name if self.tenant else None,
            "username": self.user.username if self.user else None,
            "full_name": self.user.full_name if self.user else None,
            "access_role": self.access_role,
            "is_active": self.is_active,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }

from datetime import datetime

from ..extensions.database import db


class Tenant(db.Model):
    __tablename__ = "tenants"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    slug = db.Column(db.String(120), nullable=False, unique=True)
    schema_name = db.Column(db.String(160), nullable=False, unique=True)
    table_prefix = db.Column(db.String(160), nullable=False)
    logo_url = db.Column(db.String(1024), nullable=True)
    primary_color = db.Column(db.String(7), nullable=False, default="#0F4C5C")
    secondary_color = db.Column(db.String(7), nullable=False, default="#2C7A7B")
    is_active = db.Column(db.Boolean, nullable=False, default=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "slug": self.slug,
            "schema_name": self.schema_name,
            "table_prefix": self.table_prefix,
            "logo_url": self.logo_url,
            "primary_color": self.primary_color,
            "secondary_color": self.secondary_color,
            "is_active": self.is_active,
        }
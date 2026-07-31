from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import InventoryTransactionType


class InventoryItem(db.Model):
    __tablename__ = "inventory_items"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    site_id = db.Column(db.Integer, db.ForeignKey("sites.id"), nullable=False)
    item_name = db.Column(db.String(255), nullable=False)
    category = db.Column(db.String(120), nullable=False)
    unit_of_measure = db.Column(db.String(40), nullable=False)
    unit_cost = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    current_quantity = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    minimum_quantity = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    storage_location = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "site_id": self.site_id,
            "item_name": self.item_name,
            "category": self.category,
            "unit_of_measure": self.unit_of_measure,
            "unit_cost": float(self.unit_cost or 0),
            "current_quantity": float(self.current_quantity or 0),
            "minimum_quantity": float(self.minimum_quantity or 0),
            "inventory_value": float(self.current_quantity or 0) * float(self.unit_cost or 0),
            "storage_location": self.storage_location,
            "low_stock": float(self.current_quantity or 0) < float(self.minimum_quantity or 0),
        }


class InventoryTransaction(db.Model):
    __tablename__ = "inventory_transactions"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    inventory_item_id = db.Column(db.Integer, db.ForeignKey("inventory_items.id"), nullable=False)
    transaction_type = db.Column(db.Enum(InventoryTransactionType), nullable=False)
    quantity_delta = db.Column(db.Numeric(12, 2), nullable=False)
    reference_note = db.Column(db.String(255), nullable=True)
    performed_by = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

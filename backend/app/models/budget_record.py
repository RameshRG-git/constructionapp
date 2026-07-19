from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import BudgetStatus


class BudgetRecord(db.Model):
    __tablename__ = "budget_records"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    site_id = db.Column(db.Integer, db.ForeignKey("sites.id"), nullable=False)
    category_name = db.Column(db.String(255), nullable=True)
    planned_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    actual_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    remaining_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    budget_status = db.Column(db.Enum(BudgetStatus), nullable=False, default=BudgetStatus.UNDER_BUDGET)
    recorded_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "site_id": self.site_id,
            "category_name": self.category_name,
            "planned_amount": float(self.planned_amount or 0),
            "actual_amount": float(self.actual_amount or 0),
            "remaining_amount": float(self.remaining_amount or 0),
            "budget_status": self.budget_status.value if self.budget_status else None,
            "recorded_at": self.recorded_at.isoformat() if self.recorded_at else None,
        }

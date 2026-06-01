from datetime import datetime

from ..extensions.database import db
from ..services.domain_rules import BudgetStatus


class BudgetRecord(db.Model):
    __tablename__ = "budget_records"

    id = db.Column(db.Integer, primary_key=True)
    project_id = db.Column(db.Integer, db.ForeignKey("projects.id"), nullable=False)
    category_name = db.Column(db.String(255), nullable=True)
    planned_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    actual_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    remaining_amount = db.Column(db.Numeric(14, 2), nullable=False, default=0)
    budget_status = db.Column(db.Enum(BudgetStatus), nullable=False, default=BudgetStatus.UNDER_BUDGET)
    recorded_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

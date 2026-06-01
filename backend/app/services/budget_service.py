from ..extensions.database import db
from ..models.budget_record import BudgetRecord


class BudgetService:
    @staticmethod
    def create_budget_record(**fields):
        record = BudgetRecord(**fields)
        db.session.add(record)
        db.session.commit()
        return record

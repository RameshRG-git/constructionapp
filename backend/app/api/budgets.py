from flask import Blueprint, request

from .response import created, ok
from ..services.budget_service import BudgetService


budgets_bp = Blueprint("budgets", __name__)


@budgets_bp.get("")
def list_budgets():
    return ok({"items": []})


@budgets_bp.post("")
def create_budget_record():
    payload = request.get_json(force=True)
    record = BudgetService.create_budget_record(**payload)
    return created({"id": record.id})

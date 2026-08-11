from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.budget_record import BudgetRecord
from ..models.inventory import InventoryItem
from ..models.work_assignment import WorkAssignment
from ..services.budget_service import BudgetService
from ..services.domain_rules import BudgetStatus
from ..services.tenancy import get_request_tenant_name


budgets_bp = Blueprint("budgets", __name__)


@budgets_bp.get("/sites/<int:site_id>/budgets")
def list_budgets(site_id):
    tenant_name = get_request_tenant_name()
    query = BudgetRecord.query.filter(BudgetRecord.site_id == site_id, BudgetRecord.tenant_name == tenant_name)
    status = request.args.get("budget_status")
    sort_by = request.args.get("sort_by", "recorded_at")
    sort_order = request.args.get("sort_order", "desc")

    if status:
        query = query.filter(BudgetRecord.budget_status == BudgetStatus(status))

    items = query.all()
    sortable = {
        "recorded_at": lambda record: record.recorded_at,
        "planned_amount": lambda record: float(record.planned_amount or 0),
        "actual_amount": lambda record: float(record.actual_amount or 0),
        "category_name": lambda record: record.category_name or "",
    }
    sort_fn = sortable.get(sort_by, sortable["recorded_at"])
    items = sorted(items, key=sort_fn, reverse=sort_order == "desc")

    planned_total = sum(float(item.planned_amount or 0) for item in items)
    actual_total = sum(float(item.actual_amount or 0) for item in items)
    payroll_total = sum(
        float(item.paid_amount or 0)
        for item in WorkAssignment.query.filter(
            WorkAssignment.site_id == site_id,
            WorkAssignment.tenant_name == tenant_name,
        ).all()
    )
    inventory_expense_total = sum(
        float(item.current_quantity or 0) * float(item.unit_cost or 0)
        for item in InventoryItem.query.filter(
            InventoryItem.site_id == site_id,
            InventoryItem.tenant_name == tenant_name,
        ).all()
    )
    total_expense = payroll_total + inventory_expense_total
    remaining_budget = actual_total - total_expense

    return ok(
        {
            "summary": {
                "planned_total": planned_total,
                "actual_total": actual_total,
                "payroll_total": payroll_total,
                "inventory_expense_total": inventory_expense_total,
                "total_expense": total_expense,
                "remaining_budget": remaining_budget,
                "variance": total_expense - planned_total,
            },
            "items": [record.to_dict() for record in items],
        }
    )


@budgets_bp.post("/sites/<int:site_id>/budgets")
def create_budget_record(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    planned_amount = payload.get("planned_amount", 0)
    actual_amount = payload.get("actual_amount", 0)
    remaining_amount = payload.get("remaining_amount", planned_amount - actual_amount)

    if actual_amount > planned_amount:
        budget_status = BudgetStatus.OVER_BUDGET
    elif actual_amount == planned_amount:
        budget_status = BudgetStatus.ON_BUDGET
    else:
        budget_status = BudgetStatus.UNDER_BUDGET

    record = BudgetService.create_budget_record(
        tenant_name=tenant_name,
        site_id=site_id,
        category_name=payload.get("category_name"),
        planned_amount=planned_amount,
        actual_amount=actual_amount,
        remaining_amount=remaining_amount,
        budget_status=BudgetStatus(payload.get("budget_status", budget_status)),
    )
    return created(record.to_dict())


@budgets_bp.patch("/budgets/<int:budget_id>")
def update_budget_record(budget_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    record = BudgetRecord.query.filter(
        BudgetRecord.id == budget_id,
        BudgetRecord.tenant_name == tenant_name,
    ).first_or_404()

    for key in ["category_name", "planned_amount", "actual_amount", "remaining_amount"]:
        if key in payload:
            setattr(record, key, payload[key])

    if "budget_status" in payload:
        record.budget_status = BudgetStatus(payload["budget_status"])

    if "planned_amount" in payload or "actual_amount" in payload:
        planned = float(record.planned_amount or 0)
        actual = float(record.actual_amount or 0)
        if actual > planned:
            record.budget_status = BudgetStatus.OVER_BUDGET
        elif actual == planned:
            record.budget_status = BudgetStatus.ON_BUDGET
        else:
            record.budget_status = BudgetStatus.UNDER_BUDGET

    if "remaining_amount" not in payload:
        record.remaining_amount = float(record.planned_amount or 0) - float(record.actual_amount or 0)

    db.session.commit()
    return ok(record.to_dict())


@budgets_bp.delete("/budgets/<int:budget_id>")
def delete_budget_record(budget_id):
    tenant_name = get_request_tenant_name()
    record = BudgetRecord.query.filter(
        BudgetRecord.id == budget_id,
        BudgetRecord.tenant_name == tenant_name,
    ).first_or_404()
    db.session.delete(record)
    db.session.commit()
    return ok({"deleted": True, "id": budget_id})

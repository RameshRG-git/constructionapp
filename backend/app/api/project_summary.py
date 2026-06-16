from flask import Blueprint

from .response import ok
from ..models.budget_record import BudgetRecord
from ..models.inventory import InventoryItem
from ..models.project import Project
from ..models.work_assignment import WorkAssignment
from ..services.domain_rules import WorkStatus


project_summary_bp = Blueprint("project_summary", __name__)


@project_summary_bp.get("/projects/<int:project_id>/summary")
def get_project_summary(project_id):
    project = Project.query.get_or_404(project_id)

    inventory_items = InventoryItem.query.filter(InventoryItem.project_id == project_id).all()
    low_stock_items = [
        item for item in inventory_items if float(item.current_quantity or 0) < float(item.minimum_quantity or 0)
    ]

    assignments = WorkAssignment.query.filter(WorkAssignment.project_id == project_id).all()
    open_assignments = [assignment for assignment in assignments if assignment.status != WorkStatus.COMPLETED]

    budgets = BudgetRecord.query.filter(BudgetRecord.project_id == project_id).all()
    planned_total = sum(float(record.planned_amount or 0) for record in budgets)
    actual_total = sum(float(record.actual_amount or 0) for record in budgets)

    return ok(
        {
            "project_id": project.id,
            "project_name": project.name,
            "status": project.status.value if project.status else None,
            "inventory_risk_count": len(low_stock_items),
            "workload_items": [assignment.to_dict() for assignment in open_assignments],
            "budget_variance": actual_total - planned_total,
        }
    )


@project_summary_bp.get("/reports/overview")
def get_reports_overview():
    projects = Project.query.all()
    inventory_items = InventoryItem.query.all()
    assignments = WorkAssignment.query.all()
    budgets = BudgetRecord.query.all()

    low_stock_count = sum(
        1 for item in inventory_items if float(item.current_quantity or 0) < float(item.minimum_quantity or 0)
    )
    open_assignments = sum(1 for assignment in assignments if assignment.status != WorkStatus.COMPLETED)
    planned_total = sum(float(record.planned_amount or 0) for record in budgets)
    actual_total = sum(float(record.actual_amount or 0) for record in budgets)

    return ok(
        {
            "totals": {
                "projects": len(projects),
                "inventory_alerts": low_stock_count,
                "open_workloads": open_assignments,
                "budget_variance": actual_total - planned_total,
            }
        }
    )

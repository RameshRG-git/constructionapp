from flask import Blueprint

from .response import ok
from ..models.budget_record import BudgetRecord
from ..models.inventory import InventoryItem
from ..models.site import Site
from ..models.work_assignment import WorkAssignment
from ..services.domain_rules import WorkStatus
from ..services.tenancy import get_request_tenant_name


site_summary_bp = Blueprint("site_summary", __name__)


@site_summary_bp.get("/sites/<int:site_id>/summary")
def get_site_summary(site_id):
    tenant_name = get_request_tenant_name()
    site = Site.query.filter(Site.id == site_id, Site.tenant_name == tenant_name).first_or_404()

    inventory_items = InventoryItem.query.filter(
        InventoryItem.site_id == site_id,
        InventoryItem.tenant_name == tenant_name,
    ).all()
    low_stock_items = [
        item for item in inventory_items if float(item.current_quantity or 0) < float(item.minimum_quantity or 0)
    ]

    assignments = WorkAssignment.query.filter(
        WorkAssignment.site_id == site_id,
        WorkAssignment.tenant_name == tenant_name,
    ).all()
    open_assignments = [assignment for assignment in assignments if assignment.status != WorkStatus.COMPLETED]

    budgets = BudgetRecord.query.filter(
        BudgetRecord.site_id == site_id,
        BudgetRecord.tenant_name == tenant_name,
    ).all()
    planned_total = sum(float(record.planned_amount or 0) for record in budgets)
    actual_total = sum(float(record.actual_amount or 0) for record in budgets)

    return ok(
        {
            "site_id": site.id,
            "site_name": site.name,
            "status": site.status.value if site.status else None,
            "inventory_risk_count": len(low_stock_items),
            "workload_items": [assignment.to_dict() for assignment in open_assignments],
            "budget_variance": actual_total - planned_total,
        }
    )


@site_summary_bp.get("/reports/overview")
def get_reports_overview():
    tenant_name = get_request_tenant_name()
    sites = Site.query.filter(Site.tenant_name == tenant_name).all()
    inventory_items = InventoryItem.query.filter(InventoryItem.tenant_name == tenant_name).all()
    assignments = WorkAssignment.query.filter(WorkAssignment.tenant_name == tenant_name).all()
    budgets = BudgetRecord.query.filter(BudgetRecord.tenant_name == tenant_name).all()

    low_stock_count = sum(
        1 for item in inventory_items if float(item.current_quantity or 0) < float(item.minimum_quantity or 0)
    )
    open_assignments = sum(1 for assignment in assignments if assignment.status != WorkStatus.COMPLETED)
    planned_total = sum(float(record.planned_amount or 0) for record in budgets)
    actual_total = sum(float(record.actual_amount or 0) for record in budgets)

    return ok(
        {
            "totals": {
                "sites": len(sites),
                "inventory_alerts": low_stock_count,
                "open_workloads": open_assignments,
                "budget_variance": actual_total - planned_total,
            }
        }
    )
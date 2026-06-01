from flask import Blueprint

from .response import ok


project_summary_bp = Blueprint("project_summary", __name__)


@project_summary_bp.get("/projects/<int:project_id>/summary")
def get_project_summary(project_id):
    return ok(
        {
            "project_id": project_id,
            "status": "planned",
            "inventory_risk_count": 0,
            "workload_items": [],
            "budget_variance": 0,
        }
    )

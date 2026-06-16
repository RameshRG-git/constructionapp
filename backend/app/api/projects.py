from datetime import datetime

from flask import Blueprint, request
from sqlalchemy import asc, desc

from .response import created, ok
from ..models.project import Project
from ..services.domain_rules import ProjectStatus
from ..services.project_service import ProjectService


projects_bp = Blueprint("projects", __name__)


@projects_bp.get("")
def list_projects():
    query = Project.query

    status = request.args.get("status")
    owner_name = request.args.get("owner_name")
    q = request.args.get("q")
    sort_by = request.args.get("sort_by", "created_at")
    sort_order = request.args.get("sort_order", "desc")

    if status:
        query = query.filter(Project.status == ProjectStatus(status))
    if owner_name:
        query = query.filter(Project.owner_name.ilike(f"%{owner_name}%"))
    if q:
        query = query.filter(
            Project.name.ilike(f"%{q}%")
            | Project.site_location.ilike(f"%{q}%")
            | Project.owner_name.ilike(f"%{q}%")
        )

    sortable_columns = {
        "name": Project.name,
        "site_location": Project.site_location,
        "owner_name": Project.owner_name,
        "planned_start_date": Project.planned_start_date,
        "planned_end_date": Project.planned_end_date,
        "status": Project.status,
        "created_at": Project.created_at,
    }
    sort_column = sortable_columns.get(sort_by, Project.created_at)
    query = query.order_by(asc(sort_column) if sort_order == "asc" else desc(sort_column))

    projects = query.all()
    return ok({"items": [project.to_dict() for project in projects]})


@projects_bp.get("/<int:project_id>")
def get_project(project_id):
    project = Project.query.get_or_404(project_id)
    return ok(project.to_dict())


@projects_bp.post("")
def create_project():
    payload = request.get_json(force=True)
    planned_start_date = datetime.fromisoformat(payload["planned_start_date"]).date()
    planned_end_date = payload.get("planned_end_date")
    project = ProjectService.create_project(
        name=payload["name"],
        site_location=payload["site_location"],
        owner_name=payload["owner_name"],
        planned_start_date=planned_start_date,
        planned_end_date=datetime.fromisoformat(planned_end_date).date() if planned_end_date else planned_start_date,
        status=ProjectStatus(payload.get("status", ProjectStatus.PLANNED)),
    )
    return created(project.to_dict())


@projects_bp.patch("/<int:project_id>")
def update_project(project_id):
    payload = request.get_json(force=True)
    project = Project.query.get_or_404(project_id)
    updates = {}
    for key in ["name", "site_location", "owner_name"]:
        if key in payload:
            updates[key] = payload[key]
    if "status" in payload:
        updates["status"] = ProjectStatus(payload["status"])
    if "planned_start_date" in payload:
        updates["planned_start_date"] = datetime.fromisoformat(payload["planned_start_date"]).date()
    if "planned_end_date" in payload:
        end_date = payload["planned_end_date"]
        updates["planned_end_date"] = datetime.fromisoformat(end_date).date() if end_date else project.planned_start_date
    updated = ProjectService.update_project(project, **updates)
    return ok(updated.to_dict())


@projects_bp.post("/<int:project_id>/close")
def close_project(project_id):
    project = Project.query.get_or_404(project_id)
    updated = ProjectService.update_project(project, status=ProjectStatus.CLOSED)
    return ok(updated.to_dict())

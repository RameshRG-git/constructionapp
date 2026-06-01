from datetime import datetime

from flask import Blueprint, request

from .response import created, ok
from ..models.project import Project
from ..services.domain_rules import ProjectStatus
from ..services.project_service import ProjectService


projects_bp = Blueprint("projects", __name__)


@projects_bp.get("")
def list_projects():
    projects = ProjectService.list_projects()
    return ok({"items": [project.to_dict() for project in projects]})


@projects_bp.post("")
def create_project():
    payload = request.get_json(force=True)
    project = ProjectService.create_project(
        name=payload["name"],
        site_location=payload["site_location"],
        owner_name=payload["owner_name"],
        planned_start_date=datetime.fromisoformat(payload["planned_start_date"]).date(),
        planned_end_date=datetime.fromisoformat(payload["planned_end_date"]).date(),
        status=ProjectStatus(payload.get("status", ProjectStatus.PLANNED)),
    )
    return created(project.to_dict())


@projects_bp.patch("/<int:project_id>")
def update_project(project_id):
    payload = request.get_json(force=True)
    project = Project.query.get_or_404(project_id)
    updates = {}
    for key in ["name", "site_location", "owner_name", "status"]:
        if key in payload:
            updates[key] = payload[key]
    if "planned_start_date" in payload:
        updates["planned_start_date"] = datetime.fromisoformat(payload["planned_start_date"]).date()
    if "planned_end_date" in payload:
        updates["planned_end_date"] = datetime.fromisoformat(payload["planned_end_date"]).date()
    updated = ProjectService.update_project(project, **updates)
    return ok(updated.to_dict())


@projects_bp.post("/<int:project_id>/close")
def close_project(project_id):
    project = Project.query.get_or_404(project_id)
    updated = ProjectService.update_project(project, status=ProjectStatus.CLOSED)
    return ok(updated.to_dict())

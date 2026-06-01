from flask import Blueprint, request

from .response import created, ok
from ..services.workload_service import WorkloadService


workloads_bp = Blueprint("workloads", __name__)


@workloads_bp.get("")
def list_workloads():
    return ok({"items": []})


@workloads_bp.post("")
def create_workload():
    payload = request.get_json(force=True)
    assignment = WorkloadService.create_assignment(**payload)
    return created({"id": assignment.id})

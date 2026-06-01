from functools import wraps

from flask import abort


ROLE_PERMISSIONS = {
    "project_management": {"projects", "inventory", "workloads", "budgets"},
    "site_operations": {"projects", "inventory", "workloads"},
    "warehouse_control": {"inventory"},
    "finance_review": {"projects", "budgets"},
}


def require_permission(resource_name):
    def decorator(view):
        @wraps(view)
        def wrapped(*args, **kwargs):
            role_name = getattr(getattr(view, "__self__", None), "role_name", None)
            allowed_resources = ROLE_PERMISSIONS.get(role_name, set())
            if resource_name not in allowed_resources:
                abort(403, description="Role does not allow this action")
            return view(*args, **kwargs)

        return wrapped

    return decorator

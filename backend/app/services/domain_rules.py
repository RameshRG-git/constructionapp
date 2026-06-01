from enum import Enum


class ProjectStatus(str, Enum):
    PLANNED = "planned"
    ACTIVE = "active"
    ON_HOLD = "on_hold"
    CLOSED = "closed"


class WorkStatus(str, Enum):
    OPEN = "open"
    IN_PROGRESS = "in_progress"
    BLOCKED = "blocked"
    COMPLETED = "completed"


class BudgetStatus(str, Enum):
    UNDER_BUDGET = "under_budget"
    ON_BUDGET = "on_budget"
    OVER_BUDGET = "over_budget"


class InventoryTransactionType(str, Enum):
    RECEIVED = "received"
    ISSUED = "issued"
    CORRECTED = "corrected"


def ensure_non_negative(value, field_name):
    if value is None or value < 0:
        raise ValueError(f"{field_name} must be non-negative")

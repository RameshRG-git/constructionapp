from .budgets import budgets_bp
from .inventory import inventory_bp
from .site_summary import site_summary_bp
from .sites import sites_bp
from .tenants import tenants_bp
from .workloads import workloads_bp

__all__ = [
    "budgets_bp",
    "inventory_bp",
    "site_summary_bp",
    "sites_bp",
    "tenants_bp",
    "workloads_bp",
]
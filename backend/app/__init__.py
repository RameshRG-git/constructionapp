from flask import Flask

from .api.budgets import budgets_bp
from .api.errors import register_error_handlers
from .api.inventory import inventory_bp
from .api.site_summary import site_summary_bp
from .api.sites import sites_bp
from .api.tenants import tenants_bp
from .api.workloads import workloads_bp
from .config import DevelopmentConfig
from .extensions import init_extensions
from .extensions.database import db
from .extensions.logging import configure_logging
from .services.tenancy import ensure_default_tenant, get_request_tenant_name


def create_app(config_object=DevelopmentConfig):
    app = Flask(__name__)
    app.config.from_object(config_object)

    configure_logging(app)
    init_extensions(app)
    register_error_handlers(app)

    @app.before_request
    def bind_tenant_context():
        get_request_tenant_name()

    app.register_blueprint(sites_bp, url_prefix="/api/v1/sites")
    app.register_blueprint(site_summary_bp, url_prefix="/api/v1")
    app.register_blueprint(inventory_bp, url_prefix="/api/v1")
    app.register_blueprint(workloads_bp, url_prefix="/api/v1")
    app.register_blueprint(budgets_bp, url_prefix="/api/v1")
    app.register_blueprint(tenants_bp, url_prefix="/api/v1")

    with app.app_context():
        db.create_all()
        ensure_default_tenant()

    @app.get("/api/v1/health")
    def health_check():
        return {"status": "ok"}

    return app

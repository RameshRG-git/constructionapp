from flask import Flask

from .api.budgets import budgets_bp
from .api.errors import register_error_handlers
from .api.inventory import inventory_bp
from .api.project_summary import project_summary_bp
from .api.projects import projects_bp
from .api.workloads import workloads_bp
from .config import DevelopmentConfig
from .extensions import init_extensions
from .extensions.logging import configure_logging


def create_app(config_object=DevelopmentConfig):
    app = Flask(__name__)
    app.config.from_object(config_object)

    configure_logging(app)
    init_extensions(app)
    register_error_handlers(app)

    app.register_blueprint(projects_bp, url_prefix="/api/v1/projects")
    app.register_blueprint(project_summary_bp, url_prefix="/api/v1")
    app.register_blueprint(inventory_bp, url_prefix="/api/v1/inventory")
    app.register_blueprint(workloads_bp, url_prefix="/api/v1/workloads")
    app.register_blueprint(budgets_bp, url_prefix="/api/v1/budgets")

    @app.get("/api/v1/health")
    def health_check():
        return {"status": "ok"}

    return app

from ..extensions.database import db
from ..models.project import Project


class ProjectService:
    @staticmethod
    def list_projects():
        return Project.query.order_by(Project.created_at.desc()).all()

    @staticmethod
    def create_project(**fields):
        project = Project(**fields)
        db.session.add(project)
        db.session.commit()
        return project

    @staticmethod
    def update_project(project, **fields):
        for key, value in fields.items():
            setattr(project, key, value)
        db.session.commit()
        return project

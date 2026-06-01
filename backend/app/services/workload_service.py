from ..extensions.database import db
from ..models.work_assignment import WorkAssignment


class WorkloadService:
    @staticmethod
    def create_assignment(**fields):
        assignment = WorkAssignment(**fields)
        db.session.add(assignment)
        db.session.commit()
        return assignment

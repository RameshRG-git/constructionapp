from ..extensions.database import db
from ..models.sick_leave import SickLeave


class SickLeaveService:
    @staticmethod
    def create(**fields):
        leave = SickLeave(**fields)
        db.session.add(leave)
        db.session.commit()
        return leave

    @staticmethod
    def delete(leave):
        db.session.delete(leave)
        db.session.commit()

    @staticmethod
    def sick_dates_for_member(tenant_name, team_member_id, window_start, window_end):
        """Set of sick dates for the employee that overlap [window_start, window_end]."""
        leaves = SickLeave.query.filter(
            SickLeave.tenant_name == tenant_name,
            SickLeave.team_member_id == team_member_id,
            SickLeave.start_date <= window_end,
            SickLeave.end_date >= window_start,
        ).all()

        dates = set()
        for leave in leaves:
            start = max(leave.start_date, window_start)
            end = min(leave.end_date, window_end)
            cursor = start
            while cursor <= end:
                dates.add(cursor)
                cursor = cursor.fromordinal(cursor.toordinal() + 1)
        return dates

from ..extensions.database import db
from ..models.team_member import TeamMember


class TeamMemberService:
    @staticmethod
    def create_member(**fields):
        member = TeamMember(**fields)
        db.session.add(member)
        db.session.commit()
        return member
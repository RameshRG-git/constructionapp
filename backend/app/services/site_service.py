from ..extensions.database import db
from ..models.site import Site


class SiteService:
    @staticmethod
    def list_sites(tenant_name):
        return Site.query.filter(Site.tenant_name == tenant_name).order_by(Site.created_at.desc()).all()

    @staticmethod
    def create_site(**fields):
        site = Site(**fields)
        db.session.add(site)
        db.session.commit()
        return site

    @staticmethod
    def update_site(site, **fields):
        for key, value in fields.items():
            setattr(site, key, value)
        db.session.commit()
        return site
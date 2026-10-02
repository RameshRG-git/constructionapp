from datetime import datetime

from ..extensions.database import db


class UserSession(db.Model):
    """Server-side record backing a browser session so it can be expired and revoked."""

    __tablename__ = "user_sessions"

    id = db.Column(db.Integer, primary_key=True)
    # SHA-256 of the cookie token; a leaked table cannot be replayed as a session.
    token_hash = db.Column(db.String(64), nullable=False, unique=True, index=True)
    user_id = db.Column(db.Integer, db.ForeignKey("app_users.id", ondelete="CASCADE"), nullable=False, index=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    last_seen_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    absolute_expires_at = db.Column(db.DateTime, nullable=False)
    revoked_at = db.Column(db.DateTime, nullable=True)
    ip_address = db.Column(db.String(64), nullable=True)
    user_agent = db.Column(db.String(255), nullable=True)

    user = db.relationship("AppUser")

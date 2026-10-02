import hashlib
import secrets
from datetime import datetime, timedelta

from flask import current_app, request
from sqlalchemy import or_

from ..extensions.database import db
from ..models.user_session import UserSession

# Avoid a DB write on every request; idle expiry may fire up to this much early, never late.
TOUCH_INTERVAL = timedelta(seconds=60)


def _hash(token):
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


class SessionService:
    @staticmethod
    def idle_timeout():
        return timedelta(minutes=current_app.config["SESSION_IDLE_TIMEOUT_MINUTES"])

    @staticmethod
    def absolute_timeout():
        return timedelta(hours=current_app.config["SESSION_ABSOLUTE_TIMEOUT_HOURS"])

    @staticmethod
    def create(user):
        now = datetime.utcnow()
        UserSession.query.filter(
            UserSession.user_id == user.id,
            or_(
                UserSession.revoked_at.isnot(None),
                UserSession.absolute_expires_at <= now,
                UserSession.last_seen_at <= now - SessionService.idle_timeout(),
            ),
        ).delete(synchronize_session=False)

        token = secrets.token_urlsafe(32)
        db.session.add(
            UserSession(
                token_hash=_hash(token),
                user_id=user.id,
                created_at=now,
                last_seen_at=now,
                absolute_expires_at=now + SessionService.absolute_timeout(),
                ip_address=request.remote_addr,
                user_agent=(request.headers.get("User-Agent") or "")[:255],
            )
        )
        db.session.commit()
        return token

    @staticmethod
    def validate(token):
        """Return (record, None) for a live session, else (None, error_code)."""
        if not token:
            return None, "unauthorized"
        record = UserSession.query.filter(UserSession.token_hash == _hash(token)).first()
        if record is None or record.revoked_at is not None:
            return None, "unauthorized"

        now = datetime.utcnow()
        if now >= record.absolute_expires_at or now - record.last_seen_at >= SessionService.idle_timeout():
            record.revoked_at = now
            db.session.commit()
            return None, "session_expired"
        return record, None

    @staticmethod
    def touch(record):
        now = datetime.utcnow()
        if now - record.last_seen_at >= TOUCH_INTERVAL:
            record.last_seen_at = now
            db.session.commit()

    @staticmethod
    def revoke(token):
        if not token:
            return
        UserSession.query.filter(
            UserSession.token_hash == _hash(token),
            UserSession.revoked_at.is_(None),
        ).update({"revoked_at": datetime.utcnow()}, synchronize_session=False)
        db.session.commit()

    @staticmethod
    def revoke_all_for_user(user_id, keep_session_id=None):
        query = UserSession.query.filter(UserSession.user_id == user_id, UserSession.revoked_at.is_(None))
        if keep_session_id is not None:
            query = query.filter(UserSession.id != keep_session_id)
        query.update({"revoked_at": datetime.utcnow()}, synchronize_session=False)

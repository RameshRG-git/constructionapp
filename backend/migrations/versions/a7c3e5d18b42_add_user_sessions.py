"""add server-side user sessions

Revision ID: a7c3e5d18b42
Revises: f4b6d9c72a15
Create Date: 2026-10-02 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


revision = "a7c3e5d18b42"
down_revision = "f4b6d9c72a15"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Startup db.create_all() may already have created this table.
    if sa.inspect(op.get_bind()).has_table("user_sessions"):
        return
    op.create_table(
        "user_sessions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(length=64), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("last_seen_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("absolute_expires_at", sa.DateTime(), nullable=False),
        sa.Column("revoked_at", sa.DateTime(), nullable=True),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("user_agent", sa.String(length=255), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["app_users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_user_sessions_token_hash"), "user_sessions", ["token_hash"], unique=True)
    op.create_index(op.f("ix_user_sessions_user_id"), "user_sessions", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_user_sessions_user_id"), table_name="user_sessions")
    op.drop_index(op.f("ix_user_sessions_token_hash"), table_name="user_sessions")
    op.drop_table("user_sessions")

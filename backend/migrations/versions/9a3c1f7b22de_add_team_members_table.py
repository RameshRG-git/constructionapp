"""add team members table

Revision ID: 9a3c1f7b22de
Revises: 8d1f0d4a6b21
Create Date: 2026-07-31 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "9a3c1f7b22de"
down_revision = "8d1f0d4a6b21"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "team_members",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("full_name", sa.String(length=255), nullable=False),
        sa.Column("job_title", sa.String(length=120), nullable=False),
        sa.Column("daily_pay_rate", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("app_access_planned", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("access_email", sa.String(length=255), nullable=True),
        sa.Column("access_role", sa.String(length=40), nullable=False, server_default="worker"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_team_members_tenant_name"), "team_members", ["tenant_name"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_team_members_tenant_name"), table_name="team_members")
    op.drop_table("team_members")
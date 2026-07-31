"""add team role rates table

Revision ID: 1f6f89bdb115
Revises: 9a3c1f7b22de
Create Date: 2026-07-31 00:00:01.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "1f6f89bdb115"
down_revision = "9a3c1f7b22de"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "team_role_rates",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("title", sa.String(length=120), nullable=False),
        sa.Column("daily_pay_rate", sa.Numeric(precision=10, scale=2), nullable=False),
        sa.Column("sort_order", sa.Integer(), nullable=False, server_default="100"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("tenant_name", "title", name="uq_team_role_rates_tenant_title"),
    )
    op.create_index(op.f("ix_team_role_rates_tenant_name"), "team_role_rates", ["tenant_name"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_team_role_rates_tenant_name"), table_name="team_role_rates")
    op.drop_table("team_role_rates")
"""add weekly workload fields

Revision ID: c4e2a19d8f71
Revises: 1f6f89bdb115
Create Date: 2026-07-31 00:00:02.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c4e2a19d8f71"
down_revision = "1f6f89bdb115"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("work_assignments", sa.Column("week_start_date", sa.Date(), nullable=True))
    op.add_column("work_assignments", sa.Column("week_end_date", sa.Date(), nullable=True))
    op.add_column("work_assignments", sa.Column("paid_amount", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"))


def downgrade() -> None:
    op.drop_column("work_assignments", "paid_amount")
    op.drop_column("work_assignments", "week_end_date")
    op.drop_column("work_assignments", "week_start_date")
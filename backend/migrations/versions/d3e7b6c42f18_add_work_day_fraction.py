"""add work day fraction to assignments

Revision ID: d3e7b6c42f18
Revises: c1f4a8d29b06
Create Date: 2026-09-17 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


revision = "d3e7b6c42f18"
down_revision = "c1f4a8d29b06"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "work_assignments",
        sa.Column("work_day_fraction", sa.Numeric(precision=3, scale=2), nullable=False, server_default="1"),
    )


def downgrade() -> None:
    op.drop_column("work_assignments", "work_day_fraction")
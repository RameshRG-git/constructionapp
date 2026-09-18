"""add entry_type to budget records for misc expenses

Revision ID: f4b6d9c72a15
Revises: e8a2c91f4d73
Create Date: 2026-09-18 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f4b6d9c72a15"
down_revision = "e8a2c91f4d73"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "budget_records",
        sa.Column("entry_type", sa.String(length=20), nullable=False, server_default="allocation"),
    )


def downgrade() -> None:
    op.drop_column("budget_records", "entry_type")

"""add unit cost to inventory items

Revision ID: d8a7b3f4c912
Revises: c4e2a19d8f71
Create Date: 2026-07-31 00:00:03.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "d8a7b3f4c912"
down_revision = "c4e2a19d8f71"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "inventory_items",
        sa.Column("unit_cost", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("inventory_items", "unit_cost")

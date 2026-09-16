"""add transaction type and comments to budget records

Revision ID: b7d2e5f61a94
Revises: a5b91c72d3e8
Create Date: 2026-09-15 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "b7d2e5f61a94"
down_revision = "a5b91c72d3e8"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column(
        "budget_records",
        sa.Column("transaction_type", sa.String(length=40), nullable=False, server_default="cash"),
    )
    op.add_column("budget_records", sa.Column("comments", sa.Text(), nullable=True))


def downgrade() -> None:
    op.drop_column("budget_records", "comments")
    op.drop_column("budget_records", "transaction_type")

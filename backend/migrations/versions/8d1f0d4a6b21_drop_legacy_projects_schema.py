"""drop legacy projects schema

Revision ID: 8d1f0d4a6b21
Revises: 2c406eeea4dd
Create Date: 2026-07-21 00:00:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect


# revision identifiers, used by Alembic.
revision = "8d1f0d4a6b21"
down_revision = "2c406eeea4dd"
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    inspector = inspect(bind)

    for table_name in ["inventory_items", "work_assignments", "budget_records"]:
        if not inspector.has_table(table_name):
            continue

        columns = {column["name"] for column in inspector.get_columns(table_name)}
        if "project_id" not in columns:
            continue

        with op.batch_alter_table(table_name) as batch_op:
            batch_op.drop_column("project_id")

    if inspector.has_table("projects"):
        op.drop_table("projects")


def downgrade():
    bind = op.get_bind()
    inspector = inspect(bind)

    for table_name in ["inventory_items", "work_assignments", "budget_records"]:
        if not inspector.has_table(table_name):
            continue

        columns = {column["name"] for column in inspector.get_columns(table_name)}
        if "project_id" in columns:
            continue

        with op.batch_alter_table(table_name) as batch_op:
            batch_op.add_column(sa.Column("project_id", sa.Integer(), nullable=True))

    if not inspector.has_table("projects"):
        # No-op: recreation of the legacy table is intentionally omitted.
        pass
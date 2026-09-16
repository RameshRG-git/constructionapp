"""add sick leaves, employee advances, advance recoveries

Revision ID: c1f4a8d29b06
Revises: b7d2e5f61a94
Create Date: 2026-09-15 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "c1f4a8d29b06"
down_revision = "b7d2e5f61a94"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "sick_leaves",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("employee_name", sa.String(length=255), nullable=False),
        sa.Column("start_date", sa.Date(), nullable=False),
        sa.Column("end_date", sa.Date(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_sick_leaves_tenant_name"), "sick_leaves", ["tenant_name"], unique=False)
    op.create_index(op.f("ix_sick_leaves_employee_name"), "sick_leaves", ["employee_name"], unique=False)

    op.create_table(
        "employee_advances",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("employee_name", sa.String(length=255), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("amount_recovered", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("granted_on", sa.Date(), nullable=False, server_default=sa.text("CURRENT_DATE")),
        sa.Column("due_date", sa.Date(), nullable=False),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_employee_advances_tenant_name"), "employee_advances", ["tenant_name"], unique=False)
    op.create_index(op.f("ix_employee_advances_employee_name"), "employee_advances", ["employee_name"], unique=False)

    op.create_table(
        "advance_recoveries",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("advance_id", sa.Integer(), nullable=False),
        sa.Column("employee_name", sa.String(length=255), nullable=False),
        sa.Column("week_start_date", sa.Date(), nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["advance_id"], ["employee_advances.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_advance_recoveries_tenant_name"), "advance_recoveries", ["tenant_name"], unique=False)
    op.create_index(op.f("ix_advance_recoveries_employee_name"), "advance_recoveries", ["employee_name"], unique=False)
    op.create_index(op.f("ix_advance_recoveries_week_start_date"), "advance_recoveries", ["week_start_date"], unique=False)

    op.add_column(
        "payroll_payments",
        sa.Column("advance_recovery_amount", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_column("payroll_payments", "advance_recovery_amount")

    op.drop_index(op.f("ix_advance_recoveries_week_start_date"), table_name="advance_recoveries")
    op.drop_index(op.f("ix_advance_recoveries_employee_name"), table_name="advance_recoveries")
    op.drop_index(op.f("ix_advance_recoveries_tenant_name"), table_name="advance_recoveries")
    op.drop_table("advance_recoveries")

    op.drop_index(op.f("ix_employee_advances_employee_name"), table_name="employee_advances")
    op.drop_index(op.f("ix_employee_advances_tenant_name"), table_name="employee_advances")
    op.drop_table("employee_advances")

    op.drop_index(op.f("ix_sick_leaves_employee_name"), table_name="sick_leaves")
    op.drop_index(op.f("ix_sick_leaves_tenant_name"), table_name="sick_leaves")
    op.drop_table("sick_leaves")

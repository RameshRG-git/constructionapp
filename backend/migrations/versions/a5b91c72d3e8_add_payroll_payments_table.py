"""add payroll payments table

Revision ID: a5b91c72d3e8
Revises: f3c8d41b9a27
Create Date: 2026-09-03 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "a5b91c72d3e8"
down_revision = "f3c8d41b9a27"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "payroll_payments",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("tenant_name", sa.String(length=120), nullable=False),
        sa.Column("site_id", sa.Integer(), nullable=False),
        sa.Column("employee_name", sa.String(length=255), nullable=False),
        sa.Column("role_title", sa.String(length=120), nullable=True),
        sa.Column("week_start_date", sa.Date(), nullable=False),
        sa.Column("week_end_date", sa.Date(), nullable=False),
        sa.Column("days_worked", sa.Numeric(precision=6, scale=2), nullable=False, server_default="0"),
        sa.Column("earned_amount", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("paid_amount", sa.Numeric(precision=12, scale=2), nullable=False, server_default="0"),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="pending"),
        sa.Column("payment_method", sa.String(length=40), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column("paid_on", sa.Date(), nullable=True),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["site_id"], ["sites.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint(
            "tenant_name",
            "site_id",
            "week_start_date",
            "employee_name",
            name="uq_payroll_payments_tenant_site_week_employee",
        ),
    )
    op.create_index(op.f("ix_payroll_payments_tenant_name"), "payroll_payments", ["tenant_name"], unique=False)
    op.create_index(op.f("ix_payroll_payments_week_start_date"), "payroll_payments", ["week_start_date"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_payroll_payments_week_start_date"), table_name="payroll_payments")
    op.drop_index(op.f("ix_payroll_payments_tenant_name"), table_name="payroll_payments")
    op.drop_table("payroll_payments")

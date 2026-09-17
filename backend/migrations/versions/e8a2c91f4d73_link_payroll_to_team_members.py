"""link payroll domain records to team members

Revision ID: e8a2c91f4d73
Revises: d3e7b6c42f18
Create Date: 2026-09-17 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


revision = "e8a2c91f4d73"
down_revision = "d3e7b6c42f18"
branch_labels = None
depends_on = None


TABLES = (
    ("work_assignments", "assignee_name"),
    ("payroll_payments", "employee_name"),
    ("sick_leaves", "employee_name"),
    ("employee_advances", "employee_name"),
    ("advance_recoveries", "employee_name"),
)


def upgrade() -> None:
    for table_name, _ in TABLES:
        op.add_column(table_name, sa.Column("team_member_id", sa.Integer(), nullable=True))

    bind = op.get_bind()
    for table_name, name_column in TABLES:
        bind.execute(
            sa.text(
                f"""
                UPDATE {table_name} AS target
                SET team_member_id = member.id
                FROM team_members AS member
                WHERE member.tenant_name = target.tenant_name
                  AND lower(trim(member.full_name)) = lower(trim(target.{name_column}))
                """
            )
        )
        unmatched = bind.execute(
            sa.text(f"SELECT count(*) FROM {table_name} WHERE team_member_id IS NULL")
        ).scalar_one()
        if unmatched:
            raise RuntimeError(f"Cannot link {unmatched} {table_name} row(s) to a team member")

        op.alter_column(table_name, "team_member_id", nullable=False)
        op.create_foreign_key(
            f"fk_{table_name}_team_member_id",
            table_name,
            "team_members",
            ["team_member_id"],
            ["id"],
            ondelete="RESTRICT",
        )
        op.create_index(op.f(f"ix_{table_name}_team_member_id"), table_name, ["team_member_id"], unique=False)

    op.drop_constraint("uq_payroll_payments_tenant_site_week_employee", "payroll_payments", type_="unique")
    op.create_unique_constraint(
        "uq_payroll_payments_tenant_site_week_member",
        "payroll_payments",
        ["tenant_name", "site_id", "week_start_date", "team_member_id"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_payroll_payments_tenant_site_week_member", "payroll_payments", type_="unique")
    op.create_unique_constraint(
        "uq_payroll_payments_tenant_site_week_employee",
        "payroll_payments",
        ["tenant_name", "site_id", "week_start_date", "employee_name"],
    )

    for table_name, _ in reversed(TABLES):
        op.drop_index(op.f(f"ix_{table_name}_team_member_id"), table_name=table_name)
        op.drop_constraint(f"fk_{table_name}_team_member_id", table_name, type_="foreignkey")
        op.drop_column(table_name, "team_member_id")
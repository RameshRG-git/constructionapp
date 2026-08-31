"""add app users and user tenant mapping tables

Revision ID: f3c8d41b9a27
Revises: d8a7b3f4c912
Create Date: 2026-08-31 00:00:00.000000
"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = "f3c8d41b9a27"
down_revision = "d8a7b3f4c912"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "app_users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("username", sa.String(length=120), nullable=False),
        sa.Column("email", sa.String(length=255), nullable=False),
        sa.Column("full_name", sa.String(length=255), nullable=False),
        sa.Column("password_hash", sa.String(length=255), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("username", name="uq_app_users_username"),
        sa.UniqueConstraint("email", name="uq_app_users_email"),
    )
    op.create_index(op.f("ix_app_users_username"), "app_users", ["username"], unique=False)
    op.create_index(op.f("ix_app_users_email"), "app_users", ["email"], unique=False)

    op.create_table(
        "user_tenants",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("tenant_id", sa.Integer(), nullable=False),
        sa.Column("tenant_slug", sa.String(length=120), nullable=False),
        sa.Column("access_role", sa.String(length=40), nullable=False, server_default="site_operations"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("created_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.Column("updated_at", sa.DateTime(), nullable=False, server_default=sa.text("CURRENT_TIMESTAMP")),
        sa.ForeignKeyConstraint(["user_id"], ["app_users.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["tenant_id"], ["tenants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "tenant_id", name="uq_user_tenants_user_tenant"),
    )
    op.create_index(op.f("ix_user_tenants_user_id"), "user_tenants", ["user_id"], unique=False)
    op.create_index(op.f("ix_user_tenants_tenant_id"), "user_tenants", ["tenant_id"], unique=False)
    op.create_index(op.f("ix_user_tenants_tenant_slug"), "user_tenants", ["tenant_slug"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_user_tenants_tenant_slug"), table_name="user_tenants")
    op.drop_index(op.f("ix_user_tenants_tenant_id"), table_name="user_tenants")
    op.drop_index(op.f("ix_user_tenants_user_id"), table_name="user_tenants")
    op.drop_table("user_tenants")

    op.drop_index(op.f("ix_app_users_email"), table_name="app_users")
    op.drop_index(op.f("ix_app_users_username"), table_name="app_users")
    op.drop_table("app_users")

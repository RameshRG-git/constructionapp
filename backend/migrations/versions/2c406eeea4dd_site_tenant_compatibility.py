"""site tenant compatibility

Revision ID: 2c406eeea4dd
Revises: 
Create Date: 2026-07-21 05:00:11.606221

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy import inspect, text


# revision identifiers, used by Alembic.
revision = '2c406eeea4dd'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    bind = op.get_bind()
    inspector = inspect(bind)
    default_tenant_name = "kaniskahomes"

    _backfill_sites_from_projects(bind, inspector, default_tenant_name)
    _ensure_related_table(bind, inspector, "inventory_items")
    _ensure_related_table(bind, inspector, "work_assignments")
    _ensure_related_table(bind, inspector, "budget_records")
    _ensure_inventory_transactions(bind, inspector)
    _sync_sites_sequence(bind)


def downgrade():
    bind = op.get_bind()
    inspector = inspect(bind)

    _drop_index_if_exists(bind, inspector, "inventory_transactions", "ix_inventory_transactions_tenant_name")

    for table_name in ["budget_records", "work_assignments", "inventory_items"]:
        _drop_index_if_exists(bind, inspector, table_name, f"ix_{table_name}_tenant_name")
        _drop_column_if_exists(bind, inspector, table_name, "site_id")
        _drop_column_if_exists(bind, inspector, table_name, "tenant_name")

    _drop_column_if_exists(bind, inspector, "inventory_transactions", "tenant_name")


def _backfill_sites_from_projects(bind, inspector, default_tenant_name):
    tables = set(inspector.get_table_names())
    if "projects" not in tables or "sites" not in tables:
        return

    bind.execute(
        text(
            """
            INSERT INTO sites (
                id,
                tenant_name,
                name,
                site_location,
                owner_name,
                planned_start_date,
                planned_end_date,
                status,
                created_at,
                updated_at
            )
            SELECT
                p.id,
                :tenant_name,
                p.name,
                p.site_location,
                p.owner_name,
                p.planned_start_date,
                p.planned_end_date,
                p.status::text::sitestatus,
                p.created_at,
                p.updated_at
            FROM projects p
            WHERE NOT EXISTS (
                SELECT 1 FROM sites s WHERE s.id = p.id
            )
            """
        ),
        {"tenant_name": default_tenant_name},
    )


def _ensure_related_table(bind, inspector, table_name):
    if not inspector.has_table(table_name):
        return

    columns = {column["name"] for column in inspector.get_columns(table_name)}
    if "tenant_name" not in columns:
        op.add_column(table_name, sa.Column("tenant_name", sa.String(length=120), nullable=True))
    if "site_id" not in columns:
        op.add_column(table_name, sa.Column("site_id", sa.Integer(), nullable=True))

    bind.execute(
        text(
            f"UPDATE {table_name} SET tenant_name = :tenant_name "
            "WHERE tenant_name IS NULL OR tenant_name = ''"
        ),
        {"tenant_name": "kaniskahomes"},
    )

    if "project_id" in columns:
        bind.execute(
            text(
                f"UPDATE {table_name} SET site_id = project_id "
                "WHERE site_id IS NULL AND project_id IS NOT NULL"
            )
        )

    _create_index_if_missing(inspector, table_name, f"ix_{table_name}_tenant_name", ["tenant_name"])


def _ensure_inventory_transactions(bind, inspector):
    table_name = "inventory_transactions"
    if not inspector.has_table(table_name):
        return

    columns = {column["name"] for column in inspector.get_columns(table_name)}
    if "tenant_name" not in columns:
        op.add_column(table_name, sa.Column("tenant_name", sa.String(length=120), nullable=True))

    bind.execute(
        text(
            """
            UPDATE inventory_transactions it
            SET tenant_name = COALESCE(ii.tenant_name, :tenant_name)
            FROM inventory_items ii
            WHERE it.inventory_item_id = ii.id
              AND (it.tenant_name IS NULL OR it.tenant_name = '')
            """
        ),
        {"tenant_name": "kaniskahomes"},
    )
    bind.execute(
        text(
            "UPDATE inventory_transactions SET tenant_name = :tenant_name "
            "WHERE tenant_name IS NULL OR tenant_name = ''"
        ),
        {"tenant_name": "kaniskahomes"},
    )

    _create_index_if_missing(inspector, table_name, "ix_inventory_transactions_tenant_name", ["tenant_name"])


def _sync_sites_sequence(bind):
    if bind.dialect.name != "postgresql":
        return

    bind.execute(
        text(
            """
            SELECT setval(
                pg_get_serial_sequence('sites', 'id'),
                COALESCE((SELECT MAX(id) FROM sites), 1),
                true
            )
            """
        )
    )


def _create_index_if_missing(inspector, table_name, index_name, columns):
    index_names = {index["name"] for index in inspector.get_indexes(table_name)}
    if index_name not in index_names:
        op.create_index(index_name, table_name, columns, unique=False)


def _drop_index_if_exists(bind, inspector, table_name, index_name):
    if not inspector.has_table(table_name):
        return
    index_names = {index["name"] for index in inspector.get_indexes(table_name)}
    if index_name in index_names:
        op.drop_index(index_name, table_name=table_name)


def _drop_column_if_exists(bind, inspector, table_name, column_name):
    if not inspector.has_table(table_name):
        return
    columns = {column["name"] for column in inspector.get_columns(table_name)}
    if column_name in columns:
        op.drop_column(table_name, column_name)

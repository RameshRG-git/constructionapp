from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.inventory import InventoryItem
from ..services.domain_rules import InventoryTransactionType
from ..services.inventory_service import InventoryService
from ..services.tenancy import get_request_tenant_name


inventory_bp = Blueprint("inventory", __name__)


def _apply_inventory_filters(query, category, low_stock, sort_by, sort_order):
    if category:
        query = query.filter(InventoryItem.category.ilike(f"%{category}%"))

    items = query.all()
    if low_stock in {"true", "false"}:
        want_low_stock = low_stock == "true"
        items = [
            item
            for item in items
            if (float(item.current_quantity or 0) < float(item.minimum_quantity or 0)) == want_low_stock
        ]

    sortable = {
        "item_name": lambda item: item.item_name or "",
        "category": lambda item: item.category or "",
        "current_quantity": lambda item: float(item.current_quantity or 0),
        "minimum_quantity": lambda item: float(item.minimum_quantity or 0),
    }
    sort_fn = sortable.get(sort_by, sortable["item_name"])
    items = sorted(items, key=sort_fn, reverse=sort_order == "desc")
    return items


@inventory_bp.get("/inventory")
def list_inventory():
    tenant_name = get_request_tenant_name()
    query = InventoryItem.query.filter(InventoryItem.tenant_name == tenant_name)
    site_id = request.args.get("site_id", type=int)
    category = request.args.get("category")
    low_stock = request.args.get("low_stock")
    sort_by = request.args.get("sort_by", "item_name")
    sort_order = request.args.get("sort_order", "asc")

    if site_id is not None:
        query = query.filter(InventoryItem.site_id == site_id)

    items = _apply_inventory_filters(query, category, low_stock, sort_by, sort_order)
    return ok({"items": [item.to_dict() for item in items]})


@inventory_bp.get("/sites/<int:site_id>/inventory")
def list_site_inventory(site_id):
    tenant_name = get_request_tenant_name()
    query = InventoryItem.query.filter(InventoryItem.site_id == site_id, InventoryItem.tenant_name == tenant_name)
    category = request.args.get("category")
    low_stock = request.args.get("low_stock")
    sort_by = request.args.get("sort_by", "item_name")
    sort_order = request.args.get("sort_order", "asc")
    items = _apply_inventory_filters(query, category, low_stock, sort_by, sort_order)

    return ok({"items": [item.to_dict() for item in items]})


@inventory_bp.post("/sites/<int:site_id>/inventory")
def create_inventory_item(site_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    item = InventoryItem(
        tenant_name=tenant_name,
        site_id=site_id,
        item_name=payload["item_name"],
        category=payload["category"],
        unit_of_measure=payload["unit_of_measure"],
        unit_cost=payload.get("unit_cost", 0),
        current_quantity=payload.get("current_quantity", 0),
        minimum_quantity=payload.get("minimum_quantity", 0),
        storage_location=payload.get("storage_location"),
    )
    db.session.add(item)
    db.session.commit()
    return created(item.to_dict())


@inventory_bp.patch("/inventory/<int:item_id>")
def update_inventory_item(item_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    item = InventoryItem.query.filter(InventoryItem.id == item_id, InventoryItem.tenant_name == tenant_name).first_or_404()
    for key in ["item_name", "category", "unit_of_measure", "storage_location"]:
        if key in payload:
            setattr(item, key, payload[key])
    for key in ["unit_cost", "current_quantity", "minimum_quantity"]:
        if key in payload:
            setattr(item, key, payload[key])
    db.session.commit()
    return ok(item.to_dict())


@inventory_bp.delete("/inventory/<int:item_id>")
def delete_inventory_item(item_id):
    tenant_name = get_request_tenant_name()
    item = InventoryItem.query.filter(InventoryItem.id == item_id, InventoryItem.tenant_name == tenant_name).first_or_404()
    db.session.delete(item)
    db.session.commit()
    return ok({"deleted": True, "id": item_id})


@inventory_bp.post("/inventory/<int:item_id>/transactions")
def adjust_stock(item_id):
    tenant_name = get_request_tenant_name()
    payload = request.get_json(force=True)
    item = InventoryItem.query.filter(InventoryItem.id == item_id, InventoryItem.tenant_name == tenant_name).first_or_404()
    updated_item, transaction = InventoryService.adjust_stock(
        item=item,
        quantity_delta=payload["quantity_delta"],
        transaction_type=InventoryTransactionType(payload["transaction_type"]),
        reference_note=payload.get("reference_note"),
        performed_by=payload.get("performed_by"),
    )
    return ok({"item": updated_item.to_dict(), "transaction_id": transaction.id})

from flask import Blueprint, request

from .response import created, ok
from ..extensions.database import db
from ..models.inventory import InventoryItem
from ..services.domain_rules import InventoryTransactionType
from ..services.inventory_service import InventoryService


inventory_bp = Blueprint("inventory", __name__)


@inventory_bp.get("/projects/<int:project_id>/inventory")
def list_project_inventory(project_id):
    query = InventoryItem.query.filter(InventoryItem.project_id == project_id)
    category = request.args.get("category")
    low_stock = request.args.get("low_stock")
    sort_by = request.args.get("sort_by", "item_name")
    sort_order = request.args.get("sort_order", "asc")

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

    return ok({"items": [item.to_dict() for item in items]})


@inventory_bp.post("/projects/<int:project_id>/inventory")
def create_inventory_item(project_id):
    payload = request.get_json(force=True)
    item = InventoryItem(
        project_id=project_id,
        item_name=payload["item_name"],
        category=payload["category"],
        unit_of_measure=payload["unit_of_measure"],
        current_quantity=payload.get("current_quantity", 0),
        minimum_quantity=payload.get("minimum_quantity", 0),
        storage_location=payload.get("storage_location"),
    )
    db.session.add(item)
    db.session.commit()
    return created(item.to_dict())


@inventory_bp.patch("/inventory/<int:item_id>")
def update_inventory_item(item_id):
    payload = request.get_json(force=True)
    item = InventoryItem.query.get_or_404(item_id)
    for key in ["item_name", "category", "unit_of_measure", "storage_location"]:
        if key in payload:
            setattr(item, key, payload[key])
    for key in ["current_quantity", "minimum_quantity"]:
        if key in payload:
            setattr(item, key, payload[key])
    db.session.commit()
    return ok(item.to_dict())


@inventory_bp.post("/inventory/<int:item_id>/transactions")
def adjust_stock(item_id):
    payload = request.get_json(force=True)
    item = InventoryItem.query.get_or_404(item_id)
    updated_item, transaction = InventoryService.adjust_stock(
        item=item,
        quantity_delta=payload["quantity_delta"],
        transaction_type=InventoryTransactionType(payload["transaction_type"]),
        reference_note=payload.get("reference_note"),
        performed_by=payload.get("performed_by"),
    )
    return ok({"item": updated_item.to_dict(), "transaction_id": transaction.id})

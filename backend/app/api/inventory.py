from flask import Blueprint, request

from .response import created, ok
from ..models.inventory import InventoryItem
from ..services.inventory_service import InventoryService
from ..services.domain_rules import InventoryTransactionType


inventory_bp = Blueprint("inventory", __name__)


@inventory_bp.get("")
def list_inventory():
    return ok({"items": [item.to_dict() for item in InventoryItem.query.all()]})


@inventory_bp.post("")
def create_inventory_item():
    payload = request.get_json(force=True)
    item = InventoryItem(
        project_id=payload["project_id"],
        item_name=payload["item_name"],
        category=payload["category"],
        unit_of_measure=payload["unit_of_measure"],
        current_quantity=payload.get("current_quantity", 0),
        minimum_quantity=payload.get("minimum_quantity", 0),
        storage_location=payload.get("storage_location"),
    )
    from ..extensions.database import db

    db.session.add(item)
    db.session.commit()
    return created(item.to_dict())


@inventory_bp.post("/<int:item_id>/transactions")
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

from ..extensions.database import db
from ..models.inventory import InventoryItem, InventoryTransaction
from ..services.domain_rules import ensure_non_negative


class InventoryService:
    @staticmethod
    def adjust_stock(item, quantity_delta, transaction_type, reference_note=None, performed_by=None):
        ensure_non_negative(abs(quantity_delta), "quantity_delta")
        item.current_quantity = (item.current_quantity or 0) + quantity_delta
        transaction = InventoryTransaction(
            tenant_name=item.tenant_name,
            inventory_item_id=item.id,
            transaction_type=transaction_type,
            quantity_delta=quantity_delta,
            reference_note=reference_note,
            performed_by=performed_by,
        )
        db.session.add(transaction)
        db.session.commit()
        return item, transaction

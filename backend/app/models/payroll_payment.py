from datetime import datetime

from ..extensions.database import db


class PayrollPayment(db.Model):
    """Disbursement record for one employee for one payroll week on a site."""

    __tablename__ = "payroll_payments"

    id = db.Column(db.Integer, primary_key=True)
    tenant_name = db.Column(db.String(120), nullable=False, index=True)
    site_id = db.Column(db.Integer, db.ForeignKey("sites.id"), nullable=False)
    employee_name = db.Column(db.String(255), nullable=False)
    role_title = db.Column(db.String(120), nullable=True)
    week_start_date = db.Column(db.Date, nullable=False, index=True)
    week_end_date = db.Column(db.Date, nullable=False)
    days_worked = db.Column(db.Numeric(6, 2), nullable=False, default=0)
    earned_amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    paid_amount = db.Column(db.Numeric(12, 2), nullable=False, default=0)
    status = db.Column(db.String(20), nullable=False, default="pending")
    payment_method = db.Column(db.String(40), nullable=True)
    note = db.Column(db.Text, nullable=True)
    paid_on = db.Column(db.Date, nullable=True)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (
        db.UniqueConstraint(
            "tenant_name",
            "site_id",
            "week_start_date",
            "employee_name",
            name="uq_payroll_payments_tenant_site_week_employee",
        ),
    )

    def to_dict(self):
        return {
            "id": self.id,
            "tenant_name": self.tenant_name,
            "site_id": self.site_id,
            "employee_name": self.employee_name,
            "role_title": self.role_title,
            "week_start_date": self.week_start_date.isoformat() if self.week_start_date else None,
            "week_end_date": self.week_end_date.isoformat() if self.week_end_date else None,
            "days_worked": float(self.days_worked or 0),
            "earned_amount": float(self.earned_amount or 0),
            "paid_amount": float(self.paid_amount or 0),
            "status": self.status,
            "payment_method": self.payment_method,
            "note": self.note,
            "paid_on": self.paid_on.isoformat() if self.paid_on else None,
        }

import logging

from urllib.parse import urljoin as url_join

from odoo import _, models, fields
from odoo.exceptions import ValidationError
from odoo.addons.payment import utils as payment_utils

from ..controllers.main import ThawaniController

_logger = logging.getLogger(__name__)


class PaymentTransaction(models.Model):
    _inherit = "payment.transaction"

    def _get_specific_rendering_values(self, processing_values):
        """Override of payment to return Thawani-specific processing values.

        Note: self.ensure_one() from `_get_processing_values`

        :param dict processing_values: The generic and specific processing values of the transaction
        :return: The dict of acquirer-specific rendering values
        :rtype: dict
        """
        res = super()._get_specific_rendering_values(processing_values)
        if self.provider_code != "thawani":
            return res

        provider = self.provider_id

        payment_session_payload = self._thawani_prepare_payment_session_request_payload()
        _logger.info(
            "sending '/checkout/session' request for link creation for reference: %s", payment_session_payload.get("client_reference_id")
        )
        session_data = provider._thawani_make_request("/checkout/session", payload=payment_session_payload)
        if session_data["success"]:
            base_url = provider._thawani_get_api_url(version=False, api_keyword=False)
            payment_session = session_data["data"]["session_id"]
            self.provider_reference = payment_session
            publishable_key = provider.thawani_publishable_key
            payment_link = "%s/pay/%s" % (base_url, payment_session)
            return {"api_url": payment_link, "key": publishable_key}

        base_url = provider.get_base_url()
        return {"api_url": url_join(base_url, ThawaniController.return_url)}

    def _thawani_prepare_payment_session_request_payload(self):
        """Create the payload for the payment session request based on the transaction values.

        :return: The request payload
        :rtype: dict
        """

        def get_amount(amount, currency, base_currency):
            amount = currency._convert(amount, base_currency, self.company_id, fields.Date.today())
            return payment_utils.to_minor_currency_units(amount, base_currency, 3)

        provider = self.provider_id
        return_url = url_join(provider.get_base_url(), ThawaniController.return_url)
        success_url = return_url + "%s/True" % self.reference
        failure_url = return_url + "%s/False" % self.reference
        omr = self.env['res.currency'].search([('name', '=', 'OMR')], limit=1)
        if not omr:
            raise ValidationError(_("Thawani requires the OMR currency to be active."))

        return {
            "client_reference_id": self.reference,
            "mode": "payment",
            "products": [
                {
                    # Thawani requires integer quantities and unit amounts in minor units.
                    "name": (self.reference or _("Order"))[:40],
                    "quantity": 1,
                    "unit_amount": get_amount(self.amount, self.currency_id, omr),
                }
            ],
            "success_url": success_url,
            "cancel_url": failure_url,
            "metadata": {"Customer": self.partner_name, "order id": self.sale_order_ids[0].name if self.sale_order_ids else self.reference},
        }

    def _thawani_retrieve_session_data(self):
        """Fetch the checkout session from Thawani before trusting a redirect."""
        self.ensure_one()
        if not self.provider_reference:
            raise ValidationError(_("Thawani: Missing checkout session reference."))
        session_data = self.provider_id._thawani_make_request(
            "/checkout/session/%s" % self.provider_reference,
            method="GET",
        )
        if not session_data.get("success"):
            raise ValidationError(_("Thawani: Could not verify the checkout session."))
        data = session_data.get("data") or {}
        data.setdefault("client_reference_id", self.reference)
        return data

    def _extract_reference(self, provider_code, payment_data):
        """Override of `payment` to extract the reference from Thawani data."""
        if provider_code != "thawani":
            return super()._extract_reference(provider_code, payment_data)
        return payment_data.get("client_reference_id") or payment_data.get("reference")

    def _extract_amount_data(self, payment_data):
        """Skip amount validation because Thawani returns amounts in OMR minor units."""
        if self.provider_code != "thawani":
            return super()._extract_amount_data(payment_data)
        return None

    def _apply_updates(self, payment_data):
        """Override of `payment` to update the transaction from verified Thawani data."""
        if self.provider_code != "thawani":
            return super()._apply_updates(payment_data)

        status = str(
            payment_data.get("payment_status")
            or payment_data.get("status")
            or payment_data.get("paymentStatus")
            or ""
        ).lower()
        if payment_data.get("session_id"):
            self.provider_reference = payment_data["session_id"]

        if status in {"paid", "completed", "complete", "success", "succeeded"}:
            if self.state != "done":
                self._set_done()
        elif status in {"cancelled", "canceled", "failed", "expired", "unpaid"}:
            if self.state not in {"done", "cancel"}:
                self._set_canceled(state_message=_("Payment declined or cancelled by Thawani."))
        else:
            _logger.warning(
                "received Thawani data with unknown payment status %s for transaction %s",
                status,
                self.reference,
            )
            self._set_error(_("Unknown Thawani payment status: %s", status or _("missing")))

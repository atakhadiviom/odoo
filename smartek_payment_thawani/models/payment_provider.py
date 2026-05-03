import logging

import requests

from odoo import _, fields, models
from odoo.exceptions import ValidationError
from odoo.addons.smartek_payment_thawani import const

_logger = logging.getLogger(__name__)


class PaymentProvider(models.Model):
    _inherit = "payment.provider"

    code = fields.Selection(selection_add=[("thawani", "Thawani")], ondelete={"thawani": "set default"})
    thawani_secret_key = fields.Char(string="Secret Key", required_if_provider="thawani", groups="base.group_system")
    thawani_publishable_key = fields.Char(string="Publishable Key", required_if_provider="thawani",
                                          groups="base.group_system")

    def _thawani_get_api_url(self, version=True, api_keyword=True):
        if self.state == "enabled":
            url = "https://checkout.thawani.om"
        else:  # test environment
            url = "https://uatcheckout.thawani.om"
        if api_keyword:
            url += "/api"
        if version:
            url += "/v1"
        return url

    def _get_default_payment_method_codes(self):
        """ Override of `payment` to return the default payment method codes. """
        default_codes = super()._get_default_payment_method_codes()
        if self.code != 'thawani':
            return default_codes
        return const.DEFAULT_PAYMENT_METHODS_CODES

    def _thawani_make_request(self, endpoint, payload=None, method="POST"):
        """Make a request at thawani endpoint.

        Note: self.ensure_one()

        :param str endpoint: The endpoint to be reached by the request
        :param dict payload: The payload of the request
        :param str method: The HTTP method of the request
        :return The JSON-formatted content of the response
        :rtype: dict
        :raise: ValidationError if an HTTP error occurs
        """
        self.ensure_one()
        url = self._thawani_get_api_url() + endpoint

        headers = {"Content-Type": "application/json", "thawani-api-key": self.thawani_secret_key}
        try:
            response = requests.request(method, url, json=payload, headers=headers, timeout=60)
            try:
                response.raise_for_status()
            except requests.exceptions.HTTPError:
                _logger.exception(
                    "invalid API request at %s with data %s: %s", url, payload, response.text
                )
                try:
                    resp_json = response.json()
                    # Thawani uses 'description' key (not 'message') in error responses
                    msg = resp_json.get('description') or resp_json.get('message') or response.text
                except Exception:
                    msg = response.text
                raise ValidationError(
                    "Thawani: " + _("The communication with the API failed. Details: %s", msg)
                )
        except requests.exceptions.ConnectionError:
            _logger.exception("unable to reach endpoint at %s", url)
            raise ValidationError("Thawani: " + _("Could not establish a connection to the API."))
        try:
            return response.json()
        except ValueError:
            _logger.exception("invalid JSON response from %s: %s", url, response.text)
            raise ValidationError(
                "Thawani: " + _("The API returned an invalid response. Please try again later.")
            )

import logging
import pprint

from odoo import http
from odoo.http import request

_logger = logging.getLogger(__name__)


class ThawaniController(http.Controller):
    return_url = "/payment/thawani/return/"

    @http.route(
        return_url + "<string:reference>" + "/<string:success>",
        type="http",
        auth="public",
        methods=["GET"],
        csrf=False,
        save_session=False,
    )
    def thawani_return_from_redirect(self, reference="", success=True):
        data = {"reference": reference, "success": success}
        _logger.info("received Thawani return data : %s", pprint.pformat(data))
        tx_sudo = request.env["payment.transaction"].sudo()._search_by_reference("thawani", data)
        if tx_sudo:
            verified_data = tx_sudo._thawani_retrieve_session_data()
            _logger.info("verified Thawani session data : %s", pprint.pformat(verified_data))
            tx_sudo._process("thawani", verified_data)
        return request.redirect("/payment/status")

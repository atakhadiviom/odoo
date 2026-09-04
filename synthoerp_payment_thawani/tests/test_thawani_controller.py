from unittest.mock import patch, MagicMock
from odoo.tests.common import TransactionCase
from odoo.addons.synthoerp_payment_thawani.controllers.main import ThawaniController

class TestThawaniController(TransactionCase):

    def setUp(self):
        super().setUp()
        self.controller = ThawaniController()

    @patch('odoo.addons.synthoerp_payment_thawani.controllers.main.request')
    def test_thawani_return_from_redirect_tx_found(self, mock_request):
        # mock transaction
        mock_tx = MagicMock()
        mock_tx._thawani_retrieve_session_data.return_value = {'session_data': 'test'}

        # mock env
        mock_env = MagicMock()
        mock_env["payment.transaction"].sudo()._search_by_reference.return_value = mock_tx
        mock_request.env = mock_env

        # call controller
        res = self.controller.thawani_return_from_redirect(reference='test_ref', success='true')

        # check tx was searched
        mock_env["payment.transaction"].sudo()._search_by_reference.assert_called_once_with(
            "thawani", {"reference": "test_ref", "success": "true"}
        )

        # check methods were called
        mock_tx._thawani_retrieve_session_data.assert_called_once()
        mock_tx._process.assert_called_once_with("thawani", {'session_data': 'test'})

        # check redirect
        mock_request.redirect.assert_called_once_with("/payment/status")

    @patch('odoo.addons.synthoerp_payment_thawani.controllers.main.request')
    def test_thawani_return_from_redirect_tx_not_found(self, mock_request):
        # mock env where transaction not found
        mock_env = MagicMock()
        mock_env["payment.transaction"].sudo()._search_by_reference.return_value = False
        mock_request.env = mock_env

        # call controller
        res = self.controller.thawani_return_from_redirect(reference='bad_ref', success='false')

        # check tx was searched
        mock_env["payment.transaction"].sudo()._search_by_reference.assert_called_once_with(
            "thawani", {"reference": "bad_ref", "success": "false"}
        )

        # check redirect
        mock_request.redirect.assert_called_once_with("/payment/status")

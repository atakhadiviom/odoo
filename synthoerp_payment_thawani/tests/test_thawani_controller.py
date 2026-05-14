from unittest.mock import patch, MagicMock

from odoo.tests.common import TransactionCase
from synthoerp_payment_thawani.controllers.main import ThawaniController


class TestThawaniController(TransactionCase):

    @patch("synthoerp_payment_thawani.controllers.main.request")
    def test_thawani_return_tx_found(self, mock_request):
        """Test the return controller when a transaction is successfully found."""
        mock_tx = MagicMock()
        mock_tx._thawani_retrieve_session_data.return_value = {"status": "successful"}

        mock_env = MagicMock()
        mock_env["payment.transaction"].sudo()._search_by_reference.return_value = mock_tx
        mock_request.env = mock_env

        mock_request.redirect.return_value = "redirected"

        controller = ThawaniController()
        result = controller.thawani_return_from_redirect(reference="test_ref", success=True)

        mock_env["payment.transaction"].sudo()._search_by_reference.assert_called_once_with(
            "thawani", {"reference": "test_ref", "success": True}
        )
        mock_tx._thawani_retrieve_session_data.assert_called_once()
        mock_tx._process.assert_called_once_with("thawani", {"status": "successful"})
        mock_request.redirect.assert_called_once_with("/payment/status")
        self.assertEqual(result, "redirected")

    @patch("synthoerp_payment_thawani.controllers.main.request")
    def test_thawani_return_tx_not_found(self, mock_request):
        """Test the return controller when no matching transaction is found."""
        mock_env = MagicMock()
        mock_env["payment.transaction"].sudo()._search_by_reference.return_value = None
        mock_request.env = mock_env

        mock_request.redirect.return_value = "redirected"

        controller = ThawaniController()
        result = controller.thawani_return_from_redirect(reference="test_ref_not_found", success=False)

        mock_env["payment.transaction"].sudo()._search_by_reference.assert_called_once_with(
            "thawani", {"reference": "test_ref_not_found", "success": False}
        )
        mock_request.redirect.assert_called_once_with("/payment/status")
        self.assertEqual(result, "redirected")

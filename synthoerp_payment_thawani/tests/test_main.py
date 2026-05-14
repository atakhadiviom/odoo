from unittest.mock import patch
import werkzeug.exceptions

from odoo.tests.common import TransactionCase
from synthoerp_payment_thawani.controllers.main import ThawaniController

class TestThawaniController(TransactionCase):

    @patch('synthoerp_payment_thawani.controllers.main.payment_utils.check_access_token')
    def test_thawani_return_from_redirect_forbidden(self, mock_check_access_token):
        controller = ThawaniController()

        # Test missing token
        with self.assertRaises(werkzeug.exceptions.Forbidden):
            controller.thawani_return_from_redirect(reference='REF123', success='True')

        # Test invalid token
        mock_check_access_token.return_value = False
        with self.assertRaises(werkzeug.exceptions.Forbidden):
            controller.thawani_return_from_redirect(reference='REF123', success='True', access_token='invalid')

        # mock_check_access_token should be called with reference and 'True'
        mock_check_access_token.assert_called_with('invalid', 'REF123', 'True')

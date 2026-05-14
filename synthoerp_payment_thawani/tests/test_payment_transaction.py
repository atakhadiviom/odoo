from unittest.mock import patch
from odoo.tests.common import TransactionCase

class TestPaymentTransaction(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.provider = cls.env['payment.provider'].create({
            'name': 'Thawani Test',
            'code': 'thawani',
            'thawani_publishable_key': 'test_pub_key',
            'thawani_secret_key': 'test_secret_key',
            'state': 'test',
        })
        cls.transaction = cls.env['payment.transaction'].create({
            'amount': 100.0,
            'currency_id': cls.env.user.company_id.currency_id.id,
            'provider_id': cls.provider.id,
            'reference': 'test_reference',
            'partner_id': cls.env.user.partner_id.id,
        })

    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_get_api_url')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload')
    def test_get_specific_rendering_values_success(self, mock_prepare_payload, mock_get_api_url, mock_make_request):
        mock_prepare_payload.return_value = {'mock_key': 'mock_value'}
        mock_get_api_url.return_value = 'https://uatcheckout.thawani.om'
        mock_make_request.return_value = {
            'success': True,
            'data': {'session_id': 'test_session_id'}
        }

        processing_values = {}
        res = self.transaction._get_specific_rendering_values(processing_values)

        self.assertEqual(res.get('api_url'), 'https://uatcheckout.thawani.om/pay/test_session_id')
        self.assertEqual(res.get('key'), 'test_pub_key')
        self.assertEqual(self.transaction.provider_reference, 'test_session_id')

    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider.get_base_url')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload')
    def test_get_specific_rendering_values_failure(self, mock_prepare_payload, mock_get_base_url, mock_make_request):
        mock_prepare_payload.return_value = {'mock_key': 'mock_value'}
        mock_get_base_url.return_value = 'http://localhost:8069'
        mock_make_request.return_value = {
            'success': False
        }

        processing_values = {}
        res = self.transaction._get_specific_rendering_values(processing_values)

        self.assertEqual(res.get('api_url'), 'http://localhost:8069/payment/thawani/return/')

    def test_get_specific_rendering_values_non_thawani(self):
        original_code = self.provider.code
        self.provider.code = 'other'

        processing_values = {}
        res = self.transaction._get_specific_rendering_values(processing_values)

        self.assertNotIn('api_url', res if isinstance(res, dict) else {})

        self.provider.code = original_code

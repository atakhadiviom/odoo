from unittest.mock import patch
from odoo.tests.common import TransactionCase


class TestPaymentTransaction(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.currency_omr = cls.env['res.currency'].search([('name', '=', 'OMR')], limit=1)
        if not cls.currency_omr:
            cls.currency_omr = cls.env['res.currency'].create({'name': 'OMR', 'symbol': 'OMR'})

        cls.provider = cls.env['payment.provider'].create({
            'name': 'Thawani',
            'code': 'thawani',
            'state': 'test',
            'thawani_secret_key': 'dummy_secret',
            'thawani_publishable_key': 'dummy_pub',
        })

        cls.partner = cls.env['res.partner'].create({'name': 'Test Partner'})

        cls.transaction = cls.env['payment.transaction'].create({
            'amount': 10.0,
            'currency_id': cls.currency_omr.id,
            'provider_id': cls.provider.id,
            'reference': 'test_ref_123',
            'partner_id': cls.partner.id,
        })

    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload')
    def test_get_specific_rendering_values_success(self, mock_prepare_payload, mock_make_request):
        mock_prepare_payload.return_value = {}
        mock_make_request.return_value = {
            'success': True,
            'data': {'session_id': 'sess_123'}
        }

        rendering_values = self.transaction._get_specific_rendering_values({})

        self.assertEqual(self.transaction.provider_reference, 'sess_123')
        self.assertEqual(rendering_values['key'], 'dummy_pub')
        self.assertEqual(rendering_values['api_url'], 'https://uatcheckout.thawani.om/pay/sess_123')

    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request')
    @patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload')
    def test_get_specific_rendering_values_failure(self, mock_prepare_payload, mock_make_request):
        mock_prepare_payload.return_value = {}
        mock_make_request.return_value = {
            'success': False
        }

        rendering_values = self.transaction._get_specific_rendering_values({})

        self.assertTrue(rendering_values['api_url'].endswith('/payment/thawani/return/'))

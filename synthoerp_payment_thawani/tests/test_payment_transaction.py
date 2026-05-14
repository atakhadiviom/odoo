from unittest.mock import patch

from odoo.tests.common import TransactionCase


class TestPaymentTransaction(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        cls.currency_omr = cls.env['res.currency'].with_context(active_test=False).search([('name', '=', 'OMR')], limit=1)
        if not cls.currency_omr:
            cls.currency_omr = cls.env['res.currency'].create({
                'name': 'OMR',
                'symbol': '﷼',
                'active': True,
            })
        elif not cls.currency_omr.active:
            cls.currency_omr.active = True

        cls.partner = cls.env['res.partner'].create({
            'name': 'Test Partner',
            'email': 'test@example.com',
        })

        cls.thawani_provider = cls.env['payment.provider'].create({
            'name': 'Test Thawani Provider',
            'code': 'thawani',
            'state': 'test',
            'thawani_secret_key': 'dummy_secret_key',
            'thawani_publishable_key': 'dummy_publishable_key',
        })

        cls.thawani_transaction = cls.env['payment.transaction'].create({
            'amount': 100.0,
            'currency_id': cls.currency_omr.id,
            'provider_id': cls.thawani_provider.id,
            'reference': 'Test_TX_Thawani',
            'partner_id': cls.partner.id,
        })

        cls.other_provider = cls.env['payment.provider'].create({
            'name': 'Dummy Provider',
            'code': 'custom',
            'state': 'test',
        })

        cls.other_transaction = cls.env['payment.transaction'].create({
            'amount': 100.0,
            'currency_id': cls.currency_omr.id,
            'provider_id': cls.other_provider.id,
            'reference': 'Test_TX_Other',
            'partner_id': cls.partner.id,
        })

    def test_thawani_rendering_values_success(self):
        """Test getting rendering values with a successful Thawani session."""
        mock_response = {
            "success": True,
            "data": {"session_id": "sess_12345"}
        }
        with patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request', return_value=mock_response) as mock_make_request:
            with patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload', return_value={}):
                rendering_values = self.thawani_transaction._get_specific_rendering_values({})

                self.assertEqual(self.thawani_transaction.provider_reference, 'sess_12345')
                self.assertIn('api_url', rendering_values)
                self.assertIn('key', rendering_values)
                self.assertEqual(rendering_values['key'], 'dummy_publishable_key')
                self.assertTrue(rendering_values['api_url'].endswith('/pay/sess_12345'))
                mock_make_request.assert_called_once()

    def test_thawani_rendering_values_failure(self):
        """Test getting rendering values when Thawani session creation fails."""
        mock_response = {
            "success": False
        }
        with patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request', return_value=mock_response) as mock_make_request:
            with patch('odoo.addons.synthoerp_payment_thawani.models.payment_transaction.PaymentTransaction._thawani_prepare_payment_session_request_payload', return_value={}):
                rendering_values = self.thawani_transaction._get_specific_rendering_values({})

                self.assertIn('api_url', rendering_values)
                self.assertTrue(rendering_values['api_url'].endswith('/payment/thawani/return/'))
                mock_make_request.assert_called_once()

    def test_rendering_values_other_provider(self):
        """Test getting rendering values for a non-Thawani provider."""
        with patch('odoo.addons.synthoerp_payment_thawani.models.payment_provider.PaymentProvider._thawani_make_request') as mock_make_request:
            rendering_values = self.other_transaction._get_specific_rendering_values({})

            # Since the super method for 'none' provider typically returns an empty dict or similar
            self.assertIsInstance(rendering_values, dict)
            self.assertNotIn('api_url', rendering_values)
            mock_make_request.assert_not_called()

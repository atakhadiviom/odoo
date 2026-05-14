from odoo.tests.common import TransactionCase
from unittest.mock import MagicMock

class TestThawaniGetApiUrl(TransactionCase):

    def setUp(self):
        super().setUp()
        # Mock the provider to isolate test from DB and ORM logic as we only want to test _thawani_get_api_url
        self.provider = MagicMock()
        # Bind the method to the mock to test it as an instance method
        from synthoerp_payment_thawani.models.payment_provider import PaymentProvider
        self.provider._thawani_get_api_url = PaymentProvider._thawani_get_api_url.__get__(self.provider, PaymentProvider)

    def test_thawani_get_api_url_test_env_defaults(self):
        self.provider.state = "test"
        url = self.provider._thawani_get_api_url()
        self.assertEqual(url, "https://uatcheckout.thawani.om/api/v1")

    def test_thawani_get_api_url_prod_env_defaults(self):
        self.provider.state = "enabled"
        url = self.provider._thawani_get_api_url()
        self.assertEqual(url, "https://checkout.thawani.om/api/v1")

    def test_thawani_get_api_url_no_version(self):
        self.provider.state = "test"
        url = self.provider._thawani_get_api_url(version=False)
        self.assertEqual(url, "https://uatcheckout.thawani.om/api")

    def test_thawani_get_api_url_no_api_keyword(self):
        self.provider.state = "test"
        url = self.provider._thawani_get_api_url(api_keyword=False)
        self.assertEqual(url, "https://uatcheckout.thawani.om/v1")

    def test_thawani_get_api_url_no_version_no_api_keyword(self):
        self.provider.state = "test"
        url = self.provider._thawani_get_api_url(version=False, api_keyword=False)
        self.assertEqual(url, "https://uatcheckout.thawani.om")

from odoo.tests.common import TransactionCase

class TestPaymentProvider(TransactionCase):
    def setUp(self):
        super().setUp()
        self.provider = self.env['payment.provider'].create({
            'code': 'thawani',
            'state': 'test',
            'thawani_secret_key': 'dummy_secret',
            'thawani_publishable_key': 'dummy_publishable',
        })

    def test_thawani_get_api_url_enabled(self):
        self.provider.state = 'enabled'
        self.assertEqual(self.provider._thawani_get_api_url(version=True, api_keyword=True), "https://checkout.thawani.om/api/v1")
        self.assertEqual(self.provider._thawani_get_api_url(version=False, api_keyword=True), "https://checkout.thawani.om/api")
        self.assertEqual(self.provider._thawani_get_api_url(version=True, api_keyword=False), "https://checkout.thawani.om/v1")
        self.assertEqual(self.provider._thawani_get_api_url(version=False, api_keyword=False), "https://checkout.thawani.om")

    def test_thawani_get_api_url_test(self):
        self.provider.state = 'test'
        self.assertEqual(self.provider._thawani_get_api_url(version=True, api_keyword=True), "https://uatcheckout.thawani.om/api/v1")
        self.assertEqual(self.provider._thawani_get_api_url(version=False, api_keyword=True), "https://uatcheckout.thawani.om/api")
        self.assertEqual(self.provider._thawani_get_api_url(version=True, api_keyword=False), "https://uatcheckout.thawani.om/v1")
        self.assertEqual(self.provider._thawani_get_api_url(version=False, api_keyword=False), "https://uatcheckout.thawani.om")

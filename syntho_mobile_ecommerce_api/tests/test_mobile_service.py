import base64

from odoo.tests.common import TransactionCase


class TestMobileEcommerceApi(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.website = cls.env['website'].get_current_website()
        cls.category = cls.env['product.public.category'].create({
            'name': 'Mobile Category',
        })
        cls.product = cls.env['product.template'].create({
            'name': 'Mobile Product',
            'list_price': 125.0,
            'is_published': True,
            'sale_ok': True,
            'public_categ_ids': [(6, 0, [cls.category.id])],
        })
        cls.banner = cls.env['mobile.ecommerce.banner'].create({
            'name': 'Hero Banner',
            'title': 'Launch Offer',
            'subtitle': 'Fresh arrivals for the app',
            'image': base64.b64encode(b'mobile-banner').decode(),
            'action_kind': 'product',
            'product_tmpl_id': cls.product.id,
        })
        cls.service = cls.env['mobile.ecommerce.api']
        cls.partner = cls.env['res.partner'].create({
            'name': 'Mobile Customer',
            'email': 'mobile.customer@example.com',
            'phone': '+96870000001',
            'street': 'Muscat Street',
            'city': 'Muscat',
            'country_id': cls.env.ref('base.om').id,
        })
        cls.order = cls.env['sale.order'].create({
            'partner_id': cls.partner.id,
            'partner_invoice_id': cls.partner.id,
            'partner_shipping_id': cls.partner.id,
            'pricelist_id': cls.website.pricelist_id.id,
            'website_id': cls.website.id,
        })
        cls.env['sale.order.line'].create({
            'order_id': cls.order.id,
            'product_id': cls.product.product_variant_id.id,
            'product_uom_qty': 2.0,
            'price_unit': cls.product.list_price,
            'name': cls.product.name,
        })

    def test_get_home_payload(self):
        payload = self.service.get_home_payload(website_id=self.website.id)

        self.assertEqual(payload['website']['id'], self.website.id)
        self.assertTrue(any(item['id'] == self.banner.id for item in payload['banners']))
        self.assertTrue(any(item['id'] == self.category.id for item in payload['categories']))
        self.assertTrue(
            any(item['id'] == self.product.id for item in payload['featured_products'])
        )

    def test_search_products_filters_category(self):
        payload = self.service.search_products(
            website_id=self.website.id,
            category_id=self.category.id,
            limit=10,
            offset=0,
        )

        self.assertEqual(payload['total'], 1)
        self.assertEqual(payload['items'][0]['id'], self.product.id)

    def test_get_product_detail(self):
        payload = self.service.get_product_detail(
            product_tmpl_id=self.product.id,
            website_id=self.website.id,
        )

        self.assertEqual(payload['id'], self.product.id)
        self.assertEqual(payload['variant_id'], self.product.product_variant_id.id)
        self.assertIn('Mobile Category', payload['category_names'])

    def test_get_cart_payload_includes_checkout_flags(self):
        payload = self.service.get_cart_payload(self.order, website_id=self.website.id)

        self.assertEqual(payload['order_id'], self.order.id)
        self.assertTrue(payload['can_checkout'])
        self.assertEqual(payload['cart_quantity'], self.order.cart_quantity)
        self.assertEqual(len(payload['lines']), 1)

    def test_get_checkout_state_payload(self):
        payload = self.service.get_checkout_state_payload(
            self.order,
            self.website,
            login_required=False,
            is_authenticated=True,
            billing_complete=True,
            shipping_complete=True,
            checkout_errors=[],
        )

        self.assertEqual(payload['order_id'], self.order.id)
        self.assertTrue(payload['access_token'])
        self.assertTrue(payload['billing_complete'])
        self.assertTrue(payload['can_proceed_to_payment'])
        self.assertEqual(payload['billing_address']['id'], self.partner.id)

    def test_get_address_schema_payload(self):
        country = self.env.ref('base.om')
        payload = self.service.get_address_schema_payload(
            country,
            'billing',
            countries=country,
            address_fields=['street', 'city', 'zip'],
            required_fields={'street', 'city'},
        )

        self.assertEqual(payload['address_type'], 'billing')
        self.assertEqual(payload['selected_country_id'], country.id)
        self.assertEqual(payload['countries'][0]['code'], country.code)
        self.assertIn('street', payload['required_fields'])

    def test_get_payment_result_payload(self):
        payload = self.service.get_payment_result_payload(
            order=self.order,
            status='success',
            access_token='token-123',
        )

        self.assertEqual(payload['order_id'], self.order.id)
        self.assertEqual(payload['status'], 'success')
        self.assertEqual(payload['access_token'], 'token-123')

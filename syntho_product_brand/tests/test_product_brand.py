from odoo.tests.common import TransactionCase
from psycopg2 import IntegrityError
from odoo.tools import mute_logger

class TestProductBrand(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        # Clear existing brands to ensure a clean state
        cls.env['product.brand'].search([]).unlink()

        # We also need to clear existing product templates or at least their brand assignments
        # In this case, we just focus on the brands themselves and products created in the tests

        # Base product template for relationship tests
        cls.product_template_1 = cls.env['product.template'].create({
            'name': 'Test Product 1',
        })
        cls.product_template_2 = cls.env['product.template'].create({
            'name': 'Test Product 2',
        })

    def test_brand_creation(self):
        """Test that a brand can be created with all fields properly set."""
        brand = self.env['product.brand'].create({
            'name': 'Test Brand Name',
            'description': 'This is a test brand description.',
        })

        self.assertEqual(brand.name, 'Test Brand Name')
        self.assertEqual(brand.description, 'This is a test brand description.')
        self.assertFalse(brand.logo, 'Logo should be empty by default.')
        self.assertTrue(brand.id, 'Brand should have an ID after creation.')

    def test_name_required_validation(self):
        """Test that creating a brand without a name raises an IntegrityError."""
        with self.assertRaises(IntegrityError), mute_logger('odoo.sql_db'):
            self.env['product.brand'].create({
                'description': 'Brand without a name'
            })

    def test_brand_product_relationship(self):
        """Test the bidirectional relationship between product and brand."""
        brand = self.env['product.brand'].create({
            'name': 'Relationship Brand',
        })

        # Assign brand to products
        self.product_template_1.brand_id = brand.id
        self.product_template_2.brand_id = brand.id

        # Verify from product side
        self.assertEqual(self.product_template_1.brand_id, brand)
        self.assertEqual(self.product_template_2.brand_id, brand)

        # Verify from brand side (One2many relationship)
        self.assertIn(self.product_template_1, brand.product_ids)
        self.assertIn(self.product_template_2, brand.product_ids)
        self.assertEqual(len(brand.product_ids), 2)

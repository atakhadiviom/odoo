from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestProductUniqueReference(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.Product = cls.env['product.product']

    def test_duplicate_reference_batch(self):
        """Test that creating multiple products with the same default_code in a batch raises an error."""
        with self.assertRaises(ValidationError) as cm:
            self.Product.create([
                {
                    'name': 'Test Product A',
                    'default_code': 'TEST-BATCH-01',
                },
                {
                    'name': 'Test Product B',
                    'default_code': 'TEST-BATCH-01',
                }
            ])
        self.assertIn("The Internal Reference 'TEST-BATCH-01' must be unique across all products!", str(cm.exception))

    def test_duplicate_reference_db(self):
        """Test that creating a product with a default_code that already exists raises an error."""
        # Create the first product
        self.Product.create({
            'name': 'Test Product 1',
            'default_code': 'TEST-DB-01',
        })

        # Attempt to create a second product with the same code
        with self.assertRaises(ValidationError) as cm:
            self.Product.create({
                'name': 'Test Product 2',
                'default_code': 'TEST-DB-01',
            })
        self.assertIn("The Internal Reference 'TEST-DB-01' must be unique across all products!", str(cm.exception))

    def test_empty_reference(self):
        """Test that multiple products can be created with an empty default_code."""
        products = self.Product.create([
            {
                'name': 'Empty Code Product 1',
                'default_code': False,
            },
            {
                'name': 'Empty Code Product 2',
                'default_code': False,
            },
            {
                'name': 'Empty Code Product 3',
                'default_code': '',
            }
        ])

        self.assertEqual(len(products), 3)
        for product in products:
            self.assertFalse(product.default_code)

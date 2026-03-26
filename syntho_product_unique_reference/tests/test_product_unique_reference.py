from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestProductUniqueReference(TransactionCase):

    def test_duplicate_in_batch(self):
        """Test that creating two products with the same default_code in a single batch raises an error."""
        with self.assertRaises(ValidationError) as cm:
            self.env['product.product'].create([
                {
                    'name': 'Test Product A',
                    'default_code': 'SKU-BATCH',
                },
                {
                    'name': 'Test Product B',
                    'default_code': 'SKU-BATCH',
                }
            ])

        self.assertIn("The Internal Reference 'SKU-BATCH' must be unique across all products!", str(cm.exception))

    def test_duplicate_in_database(self):
        """Test that creating a product with a default_code that already exists raises an error."""
        # Create the first product
        self.env['product.product'].create({
            'name': 'Test Product C',
            'default_code': 'SKU-DB',
        })

        # Try to create a second product with the same default_code
        with self.assertRaises(ValidationError) as cm:
            self.env['product.product'].create({
                'name': 'Test Product D',
                'default_code': 'SKU-DB',
            })

        self.assertIn("The Internal Reference 'SKU-DB' must be unique across all products!", str(cm.exception))

    def test_no_duplicate(self):
        """Test that creating products with unique default_codes works fine."""
        # Should not raise any error
        products = self.env['product.product'].create([
            {
                'name': 'Test Product E',
                'default_code': 'SKU-UNIQUE-1',
            },
            {
                'name': 'Test Product F',
                'default_code': 'SKU-UNIQUE-2',
            }
        ])

        self.assertEqual(len(products), 2)
        self.assertEqual(products[0].default_code, 'SKU-UNIQUE-1')
        self.assertEqual(products[1].default_code, 'SKU-UNIQUE-2')

    def test_empty_codes(self):
        """Test that creating multiple products with empty or False default_codes is allowed."""
        # Should not raise any error
        products = self.env['product.product'].create([
            {
                'name': 'Test Product G',
                'default_code': False,
            },
            {
                'name': 'Test Product H',
                'default_code': '',
            }
        ])

        self.assertEqual(len(products), 2)
        self.assertFalse(products[0].default_code)
        self.assertEqual(products[1].default_code, '')

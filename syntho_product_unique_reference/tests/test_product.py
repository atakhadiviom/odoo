from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestProductProduct(TransactionCase):

    def test_duplicate_internal_reference_in_database(self):
        """Test that creating a product with an existing internal reference raises a ValidationError."""
        # Create a first product
        self.env['product.product'].create({
            'name': 'Test Product 1',
            'default_code': 'DUP_CODE'
        })

        # Attempt to create a second product with the same internal reference
        with self.assertRaises(ValidationError) as cm:
            self.env['product.product'].create({
                'name': 'Test Product 2',
                'default_code': 'DUP_CODE'
            })

        self.assertIn("The Internal Reference 'DUP_CODE' must be unique across all products!", str(cm.exception))

    def test_duplicate_internal_reference_in_batch(self):
        """Test that creating multiple products with the same internal reference in a batch raises a ValidationError."""
        with self.assertRaises(ValidationError) as cm:
            self.env['product.product'].create([
                {
                    'name': 'Test Batch Product 1',
                    'default_code': 'BATCH_DUP'
                },
                {
                    'name': 'Test Batch Product 2',
                    'default_code': 'BATCH_DUP'
                }
            ])

        self.assertIn("The Internal Reference 'BATCH_DUP' must be unique across all products!", str(cm.exception))

    def test_no_duplicate_internal_reference(self):
        """Test that creating products with unique internal references works fine."""
        # Create a first product
        self.env['product.product'].create({
            'name': 'Test Unique Product 1',
            'default_code': 'UNIQUE_CODE_1'
        })

        # Create a second product with a different internal reference
        product2 = self.env['product.product'].create({
            'name': 'Test Unique Product 2',
            'default_code': 'UNIQUE_CODE_2'
        })
        self.assertEqual(product2.default_code, 'UNIQUE_CODE_2')

    def test_empty_default_code(self):
        """Test that creating multiple products with no internal reference works fine."""
        # Create a first product without a default_code
        self.env['product.product'].create({
            'name': 'Test Empty Product 1',
        })

        # Create a second product without a default_code
        product2 = self.env['product.product'].create({
            'name': 'Test Empty Product 2',
            'default_code': False
        })

        self.assertFalse(product2.default_code)

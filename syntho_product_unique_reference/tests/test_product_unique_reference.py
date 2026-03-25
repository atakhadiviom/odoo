from odoo.tests.common import TransactionCase
from odoo.exceptions import ValidationError

class TestProductUniqueReference(TransactionCase):

    def setUp(self):
        super(TestProductUniqueReference, self).setUp()
        self.Product = self.env['product.product']

    def test_01_create_unique_reference(self):
        """Test creating products with unique references."""
        self.Product.create({'name': 'Product 1', 'default_code': 'REF001'})
        self.Product.create({'name': 'Product 2', 'default_code': 'REF002'})

    def test_02_create_duplicate_reference(self):
        """Test creating a product with a duplicate reference should raise ValidationError."""
        self.Product.create({'name': 'Product 1', 'default_code': 'REF001'})
        with self.assertRaisesRegex(ValidationError, "The Internal Reference 'REF001' must be unique across all products!"):
            self.Product.create({'name': 'Product 2', 'default_code': 'REF001'})

    def test_03_write_duplicate_reference(self):
        """Test updating a product to a duplicate reference should raise ValidationError."""
        self.Product.create({'name': 'Product 1', 'default_code': 'REF001'})
        prod2 = self.Product.create({'name': 'Product 2', 'default_code': 'REF002'})
        with self.assertRaisesRegex(ValidationError, "The Internal Reference 'REF001' must be unique across all products!"):
            prod2.write({'default_code': 'REF001'})

    def test_04_multiple_empty_references(self):
        """Test that multiple products can have empty references."""
        self.Product.create({'name': 'Product 1', 'default_code': False})
        self.Product.create({'name': 'Product 2', 'default_code': False})
        self.Product.create({'name': 'Product 3', 'default_code': ''})
        self.Product.create({'name': 'Product 4', 'default_code': ''})

    def test_05_batch_create_duplicate_reference(self):
        """Test creating multiple products in a batch with duplicate references should raise ValidationError."""
        with self.assertRaisesRegex(ValidationError, "The Internal Reference 'REF_BATCH' must be unique across all products!"):
            self.Product.create([
                {'name': 'Product 1', 'default_code': 'REF_BATCH'},
                {'name': 'Product 2', 'default_code': 'REF_BATCH'},
            ])

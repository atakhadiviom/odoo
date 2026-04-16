from odoo.tests.common import TransactionCase

class TestProductTemplatePackagingBarcode(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.product_template = cls.env['product.template'].create({
            'name': 'Test Template',
        })

    def test_product_uom_ids_relation(self):
        """Test that product_uom_ids is correctly related and configured."""
        # Check that the field exists
        self.assertIn('product_uom_ids', self.product_template._fields)

        field = self.product_template._fields['product_uom_ids']

        # Verify it's a related field to product_variant_id.product_uom_ids
        self.assertEqual(field.related, ('product_variant_id', 'product_uom_ids'))

        # Verify it is editable (readonly=False)
        self.assertFalse(field.readonly)

    def test_product_uom_ids_value(self):
        """Test that the related field actually works."""
        # Create a variant to be safe, though Odoo usually auto-creates one
        # but the template creation in setUpClass already creates a variant in standard Odoo.
        variant = self.product_template.product_variant_id
        self.assertTrue(variant, "Product variant should exist.")

        # The fields might be empty, but we verify they match
        self.assertEqual(
            self.product_template.product_uom_ids,
            variant.product_uom_ids
        )

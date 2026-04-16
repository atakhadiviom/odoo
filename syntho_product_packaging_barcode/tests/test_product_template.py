from odoo.tests.common import TransactionCase

class TestProductTemplate(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.product_template = cls.env['product.template'].create({
            'name': 'Test Packaging Barcode Template',
        })

    def test_product_uom_ids_field_definition(self):
        """Test the field definition of product_uom_ids on product.template."""
        field = self.env['product.template']._fields['product_uom_ids']
        self.assertEqual(field.type, 'one2many')
        self.assertEqual(field.related, ('product_variant_id', 'product_uom_ids'))
        self.assertFalse(field.readonly)
        self.assertEqual(field.string, 'Packaging Barcodes')

    def test_product_uom_ids_behavior(self):
        """Test that the related field maps correctly to the variant's field."""
        variant = self.product_template.product_variant_id
        self.assertTrue(variant, "Template must have a variant")
        self.assertEqual(
            self.product_template.product_uom_ids,
            variant.product_uom_ids,
            "Template product_uom_ids should match variant's product_uom_ids"
        )

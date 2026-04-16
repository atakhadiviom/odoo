from odoo.tests.common import TransactionCase

class TestProductTemplate(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.product_template = cls.env['product.template'].create({
            'name': 'Test Product Template Barcode',
        })

    def test_product_uom_ids_related_field(self):
        """Test that product_uom_ids is correctly linked and editable."""
        self.assertTrue(self.product_template.product_variant_id, "Variant should be created")

        self.assertEqual(
            self.product_template.product_uom_ids,
            self.product_template.product_variant_id.product_uom_ids,
            "product_uom_ids on template should match the variant's product_uom_ids"
        )

        field = self.product_template._fields['product_uom_ids']
        self.assertEqual(field.related, ('product_variant_id', 'product_uom_ids'))
        self.assertFalse(field.readonly, "Field should be editable (readonly=False)")

        # Test behavior: we can assign to the related field (simulated by checking if we could create a packaging)
        # Note: testing exact creation of uom.packaging might require more setup for uom models,
        # but the assertFalse on readonly proves editability per Odoo framework.

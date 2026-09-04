from odoo.tests.common import TransactionCase


class TestProductTemplate(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()

        # Create a test product template
        cls.product_template = cls.env['product.template'].create({
            'name': 'Test Packaging Barcode Product',
        })

    def test_product_uom_ids_related_and_editable(self):
        """Test product_uom_ids field relation and that it is editable."""

        # Initially empty
        self.assertFalse(self.product_template.product_uom_ids)
        self.assertFalse(self.product_template.product_variant_id.product_uom_ids)

        # Add a new record via the related field on product_template
        self.product_template.write({
            'product_uom_ids': [
                (0, 0, {
                    'barcode': '1234567890',
                })
            ]
        })

        # Verify it's created and linked
        self.assertTrue(self.product_template.product_uom_ids)
        self.assertEqual(len(self.product_template.product_uom_ids), 1)
        self.assertEqual(self.product_template.product_uom_ids.barcode, '1234567890')

        # Verify it correctly delegates to the variant
        self.assertEqual(
            self.product_template.product_uom_ids,
            self.product_template.product_variant_id.product_uom_ids,
            "The product_uom_ids on the template should mirror the variant's product_uom_ids"
        )

        # Verify editing existing record
        packaging = self.product_template.product_uom_ids[0]
        packaging.barcode = '0987654321'
        self.assertEqual(self.product_template.product_variant_id.product_uom_ids[0].barcode, '0987654321')

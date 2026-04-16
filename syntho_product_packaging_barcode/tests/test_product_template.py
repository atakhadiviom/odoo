from odoo.tests.common import TransactionCase


class TestProductTemplatePackagingBarcode(TransactionCase):

    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        # Create a new product template (which automatically creates a product variant)
        cls.product_template = cls.env['product.template'].create({
            'name': 'Test Product Template',
        })

    def test_product_uom_ids_related_field(self):
        """
        Test that the related field product_uom_ids on product.template
        correctly reflects and updates the product_variant_id.product_uom_ids.
        """
        # Get the variant
        variant = self.product_template.product_variant_id

        # Initially empty
        self.assertFalse(self.product_template.product_uom_ids)
        self.assertFalse(variant.product_uom_ids)

        # Write to the related field to add a new packaging/barcode
        # product_uom_ids relates to product.packaging which typically requires a name
        self.product_template.write({
            'product_uom_ids': [(0, 0, {
                'name': 'Test Packaging',
                'barcode': '123456789',
            })]
        })

        # Assert that the variant correctly receives the new record
        self.assertEqual(len(variant.product_uom_ids), 1)
        self.assertEqual(variant.product_uom_ids.barcode, '123456789')

        # Assert that the template also correctly reflects it
        self.assertEqual(len(self.product_template.product_uom_ids), 1)
        self.assertEqual(self.product_template.product_uom_ids.barcode, '123456789')

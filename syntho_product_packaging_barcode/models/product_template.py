from odoo import fields, models


class ProductTemplate(models.Model):
    _inherit = 'product.template'

    product_uom_ids = fields.One2many(
        related='product_variant_id.product_uom_ids',
        readonly=False,
        string='Packaging Barcodes',
    )

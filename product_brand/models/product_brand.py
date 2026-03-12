from odoo import models, fields

class ProductBrand(models.Model):
    _name = 'product.brand'
    _description = 'Product Brand'

    name = fields.Char('Brand Name', required=True)
    description = fields.Text('Description')
    logo = fields.Image('Logo')
    product_ids = fields.One2many(
        'product.template',
        'brand_id',
        string='Products'
    )

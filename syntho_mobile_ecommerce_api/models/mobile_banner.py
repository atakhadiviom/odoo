from odoo import api, fields, models
from odoo.exceptions import ValidationError


class MobileEcommerceBanner(models.Model):
    _name = 'mobile.ecommerce.banner'
    _description = 'Mobile Ecommerce Banner'
    _order = 'sequence, id'

    name = fields.Char(required=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    website_id = fields.Many2one('website', string='Website')
    title = fields.Char(required=True)
    subtitle = fields.Char()
    image = fields.Image(required=True)
    action_kind = fields.Selection(
        [
            ('product', 'Product'),
            ('category', 'Category'),
            ('url', 'External URL'),
        ],
        default='product',
        required=True,
    )
    product_tmpl_id = fields.Many2one('product.template', string='Product')
    category_id = fields.Many2one('product.public.category', string='Category')
    external_url = fields.Char(string='External URL')

    @api.constrains('action_kind', 'product_tmpl_id', 'category_id', 'external_url')
    def _check_action_target(self):
        for banner in self:
            if banner.action_kind == 'product' and not banner.product_tmpl_id:
                raise ValidationError('A product banner must target a product.')
            if banner.action_kind == 'category' and not banner.category_id:
                raise ValidationError('A category banner must target a category.')
            if banner.action_kind == 'url' and not banner.external_url:
                raise ValidationError('A URL banner must provide an external URL.')

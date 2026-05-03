from odoo import fields, models


class MobileEcommerceWishlist(models.Model):
    _name = 'mobile.ecommerce.wishlist'
    _description = 'Mobile Ecommerce Wishlist Item'
    _order = 'date_added desc, id desc'

    partner_id = fields.Many2one(
        'res.partner',
        required=True,
        ondelete='cascade',
        index=True,
    )
    product_tmpl_id = fields.Many2one(
        'product.template',
        string='Product',
        required=True,
        ondelete='cascade',
        index=True,
    )
    date_added = fields.Datetime(default=fields.Datetime.now, required=True)

    _partner_product_unique = models.Constraint(
        'UNIQUE(partner_id, product_tmpl_id)',
        'This product is already in the customer wishlist.',
    )

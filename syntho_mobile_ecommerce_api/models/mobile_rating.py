from odoo import api, fields, models
from odoo.exceptions import ValidationError


class MobileEcommerceRating(models.Model):
    _name = 'mobile.ecommerce.rating'
    _description = 'Mobile Ecommerce Product Rating'
    _order = 'date desc, id desc'

    product_tmpl_id = fields.Many2one(
        'product.template',
        string='Product',
        required=True,
        ondelete='cascade',
        index=True,
    )
    partner_id = fields.Many2one(
        'res.partner',
        required=True,
        ondelete='cascade',
        index=True,
    )
    rating = fields.Selection(
        selection=[(str(value), str(value)) for value in range(1, 6)],
        required=True,
    )
    review = fields.Text()
    date = fields.Datetime(default=fields.Datetime.now, required=True)

    _partner_product_rating_unique = models.Constraint(
        'UNIQUE(partner_id, product_tmpl_id)',
        'A customer can only rate a product once.',
    )

    @api.constrains('rating')
    def _check_rating_range(self):
        for record in self:
            if int(record.rating or 0) < 1 or int(record.rating or 0) > 5:
                raise ValidationError('Rating must be between 1 and 5.')

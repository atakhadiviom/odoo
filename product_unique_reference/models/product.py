from odoo import models, api
from odoo.exceptions import ValidationError

class ProductProduct(models.Model):
    _inherit = 'product.product'

    @api.constrains('default_code')
    def _check_default_code(self):
        for product in self:
            if product.default_code:
                # Find other products with the same default_code, excluding the current one
                # If current product has product_tmpl_id, we need to handle variations carefully.
                # Usually default_code is on product.product in Odoo, product.template delegates it if only 1 variant.
                domain = [
                    ('default_code', '=', product.default_code),
                    ('id', '!=', product.id),
                ]
                duplicate = self.search(domain, limit=1)
                if duplicate:
                    raise ValidationError("The Internal Reference '%s' must be unique across all products!" % product.default_code)

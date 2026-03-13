from odoo import models, fields, api
from odoo.exceptions import ValidationError
from collections import Counter

class ProductProduct(models.Model):
    _inherit = 'product.product'

    @api.constrains('default_code')
    def _check_default_code(self):
        # 1. Collect all default_codes from products in 'self'
        codes = [p.default_code for p in self if p.default_code]
        if not codes:
            return

        # 2. Check for duplicates within the current batch (self)
        counts = Counter(codes)
        duplicates_in_batch = [code for code, count in counts.items() if count > 1]
        if duplicates_in_batch:
            raise ValidationError("The Internal Reference '%s' must be unique across all products!" % duplicates_in_batch[0])

        # 3. Check for duplicates against the database in a single query
        domain = [
            ('default_code', 'in', codes),
            ('id', 'not in', self.ids),
        ]
        duplicate = self.search(domain, limit=1)
        if duplicate:
            raise ValidationError("The Internal Reference '%s' must be unique across all products!" % duplicate.default_code)

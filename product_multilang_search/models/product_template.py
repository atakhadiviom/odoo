from odoo import api, models
from odoo.fields import Domain


class ProductTemplate(models.Model):
    _inherit = "product.template"

    @api.model
    def name_search(self, name="", domain=None, operator="ilike", limit=100):
        result = super().name_search(name, domain, operator, limit)
        return self._extend_multilang_name_search(name, domain, operator, limit, result)

    @api.model
    def _extend_multilang_name_search(self, name, domain, operator, limit, result):
        """Append matches from other installed languages, keeping current-lang hits first."""
        if not name or operator in Domain.NEGATIVE_OPERATORS:
            return result

        result_ids = [record_id for record_id, _display_name in result]
        if limit and len(result_ids) >= limit:
            return result

        current_lang = self.env.lang
        for lang, _label in self.env["res.lang"].get_installed():
            if lang == current_lang:
                continue

            remaining = limit - len(result_ids) if limit else None
            if remaining is not None and remaining <= 0:
                break

            extra = super(ProductTemplate, self.with_context(lang=lang)).name_search(
                name,
                domain,
                operator,
                remaining or limit,
            )
            for record_id, _display_name in extra:
                if record_id not in result_ids:
                    result_ids.append(record_id)
                    if remaining is not None:
                        remaining -= 1

        if len(result_ids) == len(result):
            return result

        records = self.browse(result_ids)
        return [(record.id, record.display_name) for record in records.sudo()]

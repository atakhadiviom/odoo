from odoo.tests import tagged
from odoo.tests.common import TransactionCase


@tagged("post_install", "-at_install")
class TestProductMultilangSearch(TransactionCase):
    @classmethod
    def setUpClass(cls):
        super().setUpClass()
        cls.lang_en = cls.env.ref("base.lang_en")
        cls.lang_ar = cls.env["res.lang"].with_context(active_test=False).search(
            [("code", "=", "ar_001")], limit=1
        )
        if not cls.lang_ar:
            cls.lang_ar = cls.env["res.lang"].create(
                {
                    "name": "Arabic",
                    "code": "ar_001",
                    "iso_code": "ar",
                    "url_code": "ar",
                }
            )
        cls.lang_ar.active = True

    def _create_product_with_arabic_name(self, english_name, arabic_name):
        template = self.env["product.template"].create({"name": english_name})
        template.with_context(lang="ar_001").write({"name": arabic_name})
        return template.product_variant_id

    def test_product_search_by_arabic_name_in_english_ui(self):
        variant = self._create_product_with_arabic_name("Premium Saffron", "زعفران فاخر")

        results = self.env["product.product"].with_context(lang="en_US").name_search("زعفران")
        result_ids = [record_id for record_id, _display_name in results]

        self.assertIn(variant.id, result_ids)

    def test_product_search_by_english_name_still_works(self):
        variant = self._create_product_with_arabic_name("Premium Saffron", "زعفران فاخر")

        results = self.env["product.product"].with_context(lang="en_US").name_search("Premium")
        result_ids = [record_id for record_id, _display_name in results]

        self.assertIn(variant.id, result_ids)

    def test_template_search_by_arabic_name_in_english_ui(self):
        template = self.env["product.template"].create({"name": "Gift Box"})
        template.with_context(lang="ar_001").write({"name": "صندوق هدايا"})

        results = self.env["product.template"].with_context(lang="en_US").name_search("صندوق")
        result_ids = [record_id for record_id, _display_name in results]

        self.assertIn(template.id, result_ids)

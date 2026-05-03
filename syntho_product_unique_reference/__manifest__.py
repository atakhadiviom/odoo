{
    'name': 'Unique Product Ref',
    'version': '19.0.1.0.0',
    'summary': 'Prevent duplicate product internal references',
    'description': """
Product Unique Internal Reference
=================================

A frequent request on Reddit and from Odoo users is to prevent duplicate Internal References (SKUs) across products.
This module enforces that every product must have a unique internal reference (default_code), while still allowing empty/blank references if desired.

Features
--------
* Enforces uniqueness for the Internal Reference (default_code) field on Product Templates.
* Enforces uniqueness for the Internal Reference (default_code) field on Product Variants.
* Avoids unique constraint errors when the field is left empty or False.

Use Cases
---------
* Maintaining a strict, clean catalog where no two products share the same SKU.
* Preventing user errors during data entry.
    """,
    'author': 'SynthoERP',
    'category': 'Sales/Sales',
    'website': 'https://www.synthoerp.com/',
    'depends': ['product'],
    'images': [
        'static/description/banner.png',
        'static/description/reference_validation.png',
        'static/description/quality_summary.png',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

{
    'name': 'Product Multilang Search',
    'version': '19.0.1.0.0',
    'summary': 'Search products by name in any installed language on order lines.',
    'description': """
Product Multi-Language Search
=============================

Extends product name search so users can find products when typing a translated
name (e.g. Arabic) while the UI is in another language (e.g. English).

Applies to purchase orders, sales orders, and any screen that uses the product
Many2one search. No configuration required after install.
    """,
    'author': 'SynthoERP',
    'category': 'Sales/Sales',
    'website': 'https://www.synthoerp.com/',
    'depends': ['product'],
    'images': [
        'static/description/banner.png',
        'static/description/screenshot_search.png',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

{
    'name': 'Product Brand',
    'version': '19.0.1.0.0',
    'summary': 'Organize products with brand records and logos',
    'description': """
Product Brand
=============

A very common request from Odoo users is to organize products by Brand.
This module adds a Brand model and links it to Product Templates.
    """,
    'author': 'SynthoERP',
    'category': 'Sales/Sales',
    'website': 'https://www.synthoerp.com/',
    'depends': ['product', 'sale'],
    'data': [
        'security/ir.model.access.csv',
        'views/product_brand_views.xml',
        'views/product_template_views.xml',
    ],
    'images': [
        'static/description/banner.png',
        'static/description/brand_catalog.png',
        'static/description/product_brand_field.png',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

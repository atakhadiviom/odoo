{
    'name': 'Syntho Product Brand',
    'version': '19.0.1.0.0',
    'summary': 'Manage product brands',
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
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
}

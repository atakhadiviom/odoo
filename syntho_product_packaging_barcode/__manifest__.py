{
    'name': 'Syntho Product Packaging Barcode',
    'version': '19.0.1.0.0',
    'summary': 'Restores the Packaging/Barcode section in the product Inventory tab',
    'description': """
Product Packaging Barcode
=========================

In Odoo 19, the Packaging / Barcode section is no longer visible in the Inventory tab by default.
This module restores the visibility of the packaging section in the product Inventory tab,
allowing users to assign multiple barcodes to the same product (including box/carton barcodes).
    """,
    'author': 'SynthoERP',
    'category': 'Inventory/Inventory',
    'website': 'https://www.synthoerp.com/',
    'depends': ['stock'],
    'data': [
        'views/product_template_views.xml',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

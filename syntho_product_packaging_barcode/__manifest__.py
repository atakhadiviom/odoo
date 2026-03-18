{
    'name': 'Syntho Product Packaging Barcode',
    'version': '19.0.1.0.0',
    'summary': 'Restores the Packaging/Barcode section in the product Inventory tab',
    'description': 'Restores the hidden Packaging/Barcode section in the Odoo 19 product Inventory tab.',
    'author': 'SynthoERP',
    'category': 'Inventory/Inventory',
    'website': 'https://www.synthoerp.com/',
    'depends': ['stock'],
    'data': [
        'views/product_template_views.xml',
    ],
    'images': ['static/description/banner.png'],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

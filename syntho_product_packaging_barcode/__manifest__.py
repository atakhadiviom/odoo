{
    'name': 'Packaging Barcodes',
    'version': '19.0.1.0.0',
    'summary': 'Restore packaging barcode fields on products',
    'description': """
Packaging Barcodes
==================

Restore the Packaging / Barcodes section on the Odoo 19 product Inventory tab
for single-variant products. Maintain package-level barcode rows directly from
the product form.
    """,
    'author': 'SynthoERP',
    'category': 'Inventory/Inventory',
    'website': 'https://www.synthoerp.com/',
    'depends': ['stock'],
    'data': [
        'views/product_template_views.xml',
    ],
    'images': [
        'static/description/banner.png',
        'static/description/packaging_table.png',
        'static/description/barcode_labels.png',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

{
    'name': 'Product Images on Reports',
    'version': '19.0.1.0.0',
    'summary': 'Show product images on quotations, invoices, and purchase orders',
    'description': """
Product Images on Reports
=========================

Display product thumbnail images on PDF reports — quotations, sales orders,
customer invoices, and purchase orders — so your documents are more visual
and easier for customers and vendors to verify at a glance.

Features
--------
* Adds a product image column to Sale Order / Quotation PDF reports
* Adds a product image column to Customer Invoice PDF reports
* Adds a product image column to Purchase Order PDF reports
* Falls back gracefully if a product has no image (no broken placeholder)
* Lightweight: pure QWeb template inheritance, no new models or Python code

Use Cases
---------
* Send professional, image-rich quotations to customers
* Include product photos on invoices to reduce disputes
* Verify the correct items on purchase orders at a glance
    """,
    'author': 'SynthoERP',
    'website': 'https://www.synthoerp.com/',
    'category': 'Sales/Sales',
    'depends': ['sale', 'account', 'purchase'],
    'data': [
        'views/sale_report_inherit.xml',
        'views/account_report_inherit.xml',
        'views/purchase_order_inherit.xml',
    ],
    'images': ['static/description/banner.png'],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

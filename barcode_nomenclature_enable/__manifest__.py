{
    'name': 'Barcode Nomenclature',
    'version': '19.0.1.0.0',
    'summary': 'Manage barcode nomenclature rules from Inventory',
    'description': """
Barcode Nomenclature Enable
===========================

By default, Odoo 19 Community Edition hides the **Barcode Nomenclature** menu
under Inventory → Configuration → Products. This module makes it fully
accessible to Inventory Managers — no developer mode or technical tricks needed.

Features
--------
* Exposes **Inventory > Configuration > Products > Barcode Nomenclatures**
* Full CRUD access: create, edit, and delete nomenclatures and their rules
* Supports standard EAN-13 weight barcodes (prefix 21), price barcodes (prefix 23),
  and any custom prefix rules you define
* Compatible with scale-generated weight barcodes used in POS
* Works alongside the built-in GS1 Nomenclature (barcodes_gs1_nomenclature)

Use Cases
---------
* Add custom weight barcode rules for your weighing scale (e.g. prefix 20)
* Define price-embedded barcodes for variable-price products
* Manage multiple nomenclatures for different warehouses or POS terminals
* Test and validate barcode rules before deploying to production

Installation
------------
1. Copy the module to your custom addons path
2. Update the app list
3. Install **Barcode Nomenclature Enable**
4. Go to Inventory > Configuration > Products > Barcode Nomenclatures
    """,
    'author': 'SynthoERP',
    'website': 'https://www.synthoerp.com/',
    'category': 'Inventory',
    'depends': ['barcodes', 'stock'],
    'data': ['views/menu_views.xml'],
    'images': [
        'static/description/banner.png',
        'static/description/rule_management.png',
        'static/description/scale_barcodes.png',
    ],
    'installable': True,
    'auto_install': False,
    'license': 'LGPL-3',
    'price': 0,
    'currency': 'USD',
}

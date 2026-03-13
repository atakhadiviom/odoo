Barcode Nomenclature Enable
===========================

**Version:** 19.0.1.0.0 | **License:** LGPL-3 | **Author:** SynthoERP

Unlocks the hidden **Barcode Nomenclature** menu in Odoo 19 Community Edition,
giving Inventory Managers full CRUD access to nomenclature rules without
requiring developer mode or any technical tricks.

Features
--------

- Exposes **Inventory → Configuration → Products → Barcode Nomenclatures**
- Full create / edit / delete access for Inventory Managers
- Supports weight barcodes (prefix 20, 21), price barcodes (prefix 23), and custom rules
- Compatible with the built-in GS1 Nomenclature module
- Zero footprint: one XML file, no Python code, no database changes

Installation
------------

1. Copy ``barcode_nomenclature_enable`` to your addons path
2. Restart Odoo and update the app list
3. Install **Barcode Nomenclature Enable**
4. Go to **Inventory → Configuration → Products → Barcode Nomenclatures**

Dependencies
------------

- ``barcodes``
- ``stock``

Credits
-------

**Author:** SynthoERP — https://www.synthoerp.com/

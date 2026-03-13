Syntho Unique Product Reference
================================

**Version:** 19.0.1.0.0 | **License:** LGPL-3 | **Author:** SynthoERP

Enforce unique Internal References (SKUs) across all products and variants.

Features
--------

- Validates uniqueness of ``default_code`` on Product Variants
- Raises a clear validation error on duplicate entries
- Allows empty / blank references (uniqueness only applies when set)
- No new models, no XML data files — pure Python constraint

Installation
------------

1. Copy ``syntho_product_unique_reference`` to your addons path
2. Restart Odoo and update the app list
3. Install **Syntho Unique Prod Ref**
4. Any attempt to save a duplicate Internal Reference will now be blocked

Dependencies
------------

- ``product``

Credits
-------

**Author:** SynthoERP — https://www.synthoerp.com/

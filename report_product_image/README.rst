Product Images on Reports
=========================

**Version:** 19.0.1.0.0 | **License:** LGPL-3 | **Author:** Murjan Global

Display product thumbnail images on PDF reports — quotations, sales orders,
customer invoices, and purchase orders.

Features
--------

- Product images on Sale Order / Quotation PDF reports
- Product images on Customer Invoice PDF reports
- Product images on Purchase Order PDF reports
- Graceful fallback when a product has no image
- Lightweight: pure QWeb template inheritance, no new models or Python code

Installation
------------

1. Copy ``report_product_image`` to your addons path
2. Restart Odoo and update the app list
3. Install **Product Images on Reports**
4. Print any quotation, invoice, or purchase order — images appear automatically

Dependencies
------------

- ``sale``
- ``account``
- ``purchase``

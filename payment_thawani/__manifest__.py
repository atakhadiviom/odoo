{
    "name": "Thawani Payment",
    "category": "Accounting/Payment Provider",
    "version": "19.0.1.2.0",
    "summary": "Accept Thawani Pay checkout payments in Odoo",
    "description": """
Thawani Payment
===============

Connect Odoo payment transactions to Thawani Pay checkout sessions for Omani
eCommerce payments. The provider redirects customers to Thawani checkout and
verifies the checkout session before confirming the Odoo transaction.

Customer data sent to Thawani includes the transaction reference, order total,
customer name, and related sale order reference when available.
    """,
    "author": "Smartek",
    "depends": ["payment", "website_sale"],
    "data": [
        "views/payment_thawani_templates.xml",
        "views/payment_views.xml",
        "data/payment_provider_data.xml",
    ],
    "images": [
        "static/description/banner.png",
        "static/description/provider_settings.png",
        "static/description/payment_flow.png",
    ],
    "application": True,
    "post_init_hook": "post_init_hook",
    "uninstall_hook": "uninstall_hook",
    "installable": True,
    "license": "LGPL-3",
    "price": 0,
    "currency": "USD",
}

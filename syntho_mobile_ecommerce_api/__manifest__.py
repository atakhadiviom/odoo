{
    'name': 'Syntho Mobile Commerce',
    'version': '19.0.1.0.0',
    'summary': 'Mobile-friendly ecommerce APIs and content for Odoo storefront apps',
    'description': """
Syntho Mobile Ecommerce API
===========================

Provides a mobile-ready ecommerce API layer for Odoo 19 storefront apps.

Features
--------
* Odoo-managed mobile app settings, navigation, content pages, and home sections
* Mobile bootstrap feed for Flutter or React Native storefront apps
* Mobile home feed with banners, featured categories, and featured products
* Product listing and product detail payloads optimized for mobile clients
* Cart summary plus cart add/update endpoints
* Customer account summary and website order history endpoints
* Checkout, delivery, and hosted payment support for mobile clients
* Wishlist, product reviews, brand browsing, and barcode lookup endpoints
* Banner management and app-control menus in the Odoo backend
    """,
    'author': 'SynthoERP',
    'website': 'https://www.synthoerp.com/',
    'category': 'Website',
    'depends': [
        'website_sale',
        'syntho_product_brand',
        'syntho_product_packaging_barcode',
    ],
    'data': [
        'security/ir.model.access.csv',
        'views/mobile_app_views.xml',
        'views/mobile_banner_views.xml',
        'views/mobile_checkout_templates.xml',
    ],
    'images': [
        'static/description/banner.png',
        'static/description/icon.png',
    ],
    'installable': True,
    'application': True,
    'license': 'LGPL-3',
    'price': 0.0,
    'currency': 'USD',
}

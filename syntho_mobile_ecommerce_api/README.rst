SynthoShop Mobile Commerce
==========================

SynthoShop Mobile Commerce adds a production-ready, session-based mobile
ecommerce API and app-control backend to Odoo 19 Community Edition. It is built
for Flutter, React Native, or any mobile client that needs native catalog, cart,
checkout, account, wishlist, ratings, brand, and barcode flows while keeping
pricing, carriers, taxes, and payments authoritative in Odoo.

Key Features
------------

* Odoo-managed mobile app settings, colors, app scheme, versions, and maintenance mode
* Configurable home sections, banners, navigation items, and content pages
* Website-aware product listing, product detail, category, brand, and barcode APIs
* Cart add/update and full checkout state APIs for native mobile checkout screens
* Address schema/upsert endpoints that reuse Odoo website-sale validation helpers
* Delivery method listing/selection using Odoo carrier eligibility and pricing
* Provider-agnostic hosted payment page with mobile deep-link return bridge
* Customer account and website order history endpoints
* Authenticated wishlist and product review/rating endpoints
* Optional integration with Syntho Product Brand and Syntho Product Packaging Barcode

Mobile API Endpoints
--------------------

* ``POST /mobile_api/bootstrap``
* ``POST /mobile_api/home``
* ``POST /mobile_api/products``
* ``POST /mobile_api/product``
* ``POST /mobile_api/brands``
* ``POST /mobile_api/products/by_brand``
* ``POST /mobile_api/products/barcode``
* ``POST /mobile_api/cart``
* ``POST /mobile_api/cart/add``
* ``POST /mobile_api/cart/update``
* ``POST /mobile_api/wishlist``
* ``POST /mobile_api/wishlist/toggle``
* ``POST /mobile_api/product/rate``
* ``POST /mobile_api/checkout/state``
* ``POST /mobile_api/checkout/address_schema``
* ``POST /mobile_api/checkout/address_upsert``
* ``POST /mobile_api/checkout/delivery_methods``
* ``POST /mobile_api/checkout/delivery_select``
* ``POST /mobile_api/checkout/payment_options``
* ``POST /mobile_api/checkout/payment_session``
* ``POST /mobile_api/checkout/payment_status``
* ``POST /mobile_api/account``
* ``POST /mobile_api/orders``

Hosted Payment Routes
---------------------

* ``GET /mobile_api/checkout/payment_page/<tx_id>``
* ``GET /mobile_api/checkout/payment_return``

Configuration
-------------

Install the addon, then open **Mobile Commerce** in the Odoo backend to control
the mobile app shell, home layout, banners, navigation, and content pages.

Useful system parameters:

* ``syntho_mobile_ecommerce_api.return_url``: mobile payment deep link, for example ``synthoshop://checkout/result``
* ``syntho_mobile_ecommerce_api.public_base_url``: public URL used in API image links, useful for local proxies or reverse proxies

Flutter Client
--------------

The repository includes a companion Flutter client in ``flutter_app/``. It
supports home, catalog, product detail, cart, checkout, account, brands,
barcode lookup, wishlist, and product reviews.

License
-------

LGPL-3.

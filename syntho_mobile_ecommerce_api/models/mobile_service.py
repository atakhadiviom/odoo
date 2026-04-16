from odoo import api, models
from odoo.fields import Domain
from odoo.tools import html2plaintext


class MobileEcommerceApi(models.AbstractModel):
    _name = 'mobile.ecommerce.api'
    _description = 'Mobile Ecommerce API'

    @api.model
    def _get_website(self, website_id=None):
        if website_id:
            website = self.env['website'].browse(int(website_id)).exists()
            if website:
                return website
        return self.env['website'].get_current_website()

    @api.model
    def _base_url(self):
        config = self.env['ir.config_parameter'].sudo()
        return (
            config.get_param('syntho_mobile_ecommerce_api.public_base_url')
            or config.get_param('mobile_ecommerce_app.public_base_url')
            or config.get_param('web.base.url', '')
        ).rstrip('/')

    @api.model
    def _image_url(self, model_name, record_id, field_name='image_1920'):
        return f'{self._base_url()}/web/image/{model_name}/{record_id}/{field_name}'

    @api.model
    def _get_mobile_app(self, website_id=None):
        website = self._get_website(website_id)
        app = self.env['mobile.ecommerce.app'].sudo().search(
            [('active', '=', True), ('website_id', 'in', [False, website.id])],
            order='sequence, id',
            limit=1,
        )
        return app, website

    @api.model
    def _clean_text(self, value):
        text_value = html2plaintext(value or '')
        return ' '.join(text_value.split())

    @api.model
    def _serialize_category(self, category):
        return {
            'id': category.id,
            'name': category.name,
            'description': self._clean_text(category.website_description),
            'image_url': self._image_url('product.public.category', category.id, 'cover_image'),
        }

    @api.model
    def _get_product_rating_summary(self, product):
        ratings = self.env['mobile.ecommerce.rating'].sudo().search([
            ('product_tmpl_id', '=', product.id),
        ])
        count = len(ratings)
        average = (
            sum(int(rating.rating) for rating in ratings) / count
            if count
            else 0.0
        )
        return average, count

    @api.model
    def _serialize_product(self, product, website):
        variant = product.product_variant_id
        pricelist = (
            website.pricelist_ids[:1]
            or self.env['product.pricelist'].sudo().search(
                [('company_id', 'in', [False, website.company_id.id])],
                limit=1,
            )
        )
        price = pricelist._get_product_price(variant, 1.0) if pricelist else product.list_price
        description = self._clean_text(product.website_description or product.description_sale)
        brand = product.brand_id if 'brand_id' in product._fields else False
        average_rating, rating_count = self._get_product_rating_summary(product)
        return {
            'id': product.id,
            'variant_id': variant.id,
            'name': product.name,
            'default_code': product.default_code,
            'price': price,
            'list_price': product.list_price,
            'currency': website.currency_id.name,
            'description': description,
            'short_description': description[:160],
            'image_url': self._image_url('product.template', product.id),
            'website_url': f'{self._base_url()}{product.website_url}',
            'category_ids': product.public_categ_ids.ids,
            'category_names': product.public_categ_ids.mapped('name'),
            'brand_id': brand.id if brand else False,
            'brand_name': brand.name if brand else False,
            'avg_rating': average_rating,
            'rating_count': rating_count,
        }

    @api.model
    def _serialize_brand(self, brand, website):
        product_domain = website.sale_product_domain() & Domain('brand_id', '=', brand.id)
        return {
            'id': brand.id,
            'name': brand.name,
            'description': self._clean_text(brand.description),
            'logo_url': self._image_url('product.brand', brand.id, 'logo') if brand.logo else False,
            'product_count': self.env['product.template'].sudo().with_context(
                website_id=website.id
            ).search_count(product_domain),
        }

    @api.model
    def _serialize_rating(self, rating):
        return {
            'id': rating.id,
            'product_tmpl_id': rating.product_tmpl_id.id,
            'partner_id': rating.partner_id.id,
            'partner_name': rating.partner_id.name,
            'rating': int(rating.rating),
            'review': rating.review or '',
            'date': rating.date.isoformat() if rating.date else False,
        }

    @api.model
    def _serialize_banner(self, banner):
        return {
            'id': banner.id,
            'name': banner.name,
            'title': banner.title,
            'subtitle': banner.subtitle,
            'image_url': self._image_url('mobile.ecommerce.banner', banner.id, 'image'),
            'action_kind': banner.action_kind,
            'product_tmpl_id': banner.product_tmpl_id.id,
            'category_id': banner.category_id.id,
            'external_url': banner.external_url,
        }

    @api.model
    def _serialize_content_page(self, page):
        return {
            'id': page.id,
            'name': page.name,
            'page_key': page.page_key,
            'slug': page.slug,
            'title': page.title,
            'summary': self._clean_text(page.summary),
            'cover_image_url': self._image_url(
                'mobile.ecommerce.content.page',
                page.id,
                'cover_image',
            )
            if page.cover_image
            else False,
            'body_html': page.body_html or '',
        }

    @api.model
    def _serialize_navigation_item(self, item):
        return {
            'id': item.id,
            'label': item.label,
            'icon': item.icon or '',
            'target_kind': item.target_kind,
            'tab_key': item.tab_key,
            'category_id': item.category_id.id,
            'content_page_id': item.content_page_id.id,
            'external_url': item.external_url,
        }

    @api.model
    def _serialize_home_section(self, section, website):
        payload = {
            'id': section.id,
            'name': section.name,
            'section_key': section.section_key,
            'title': section.title,
            'subtitle': section.subtitle,
            'section_kind': section.section_kind,
            'max_items': section.max_items,
            'items': [],
        }

        if section.section_kind == 'hero_banners':
            banners = section.banner_ids.filtered('active')
            if not banners:
                banners = self.env['mobile.ecommerce.banner'].sudo().search(
                    [('active', '=', True), ('website_id', 'in', [False, website.id])],
                    order='sequence, id',
                    limit=section.max_items or 5,
                )
            payload['items'] = [self._serialize_banner(banner) for banner in banners[: section.max_items]]
        elif section.section_kind == 'featured_categories':
            categories = section.category_ids
            if not categories:
                category_domain = self.env[
                    'product.public.category'
                ]._get_available_category_domain(website.id)
                categories = self.env['product.public.category'].sudo().search(
                    category_domain & Domain('parent_id', '=', False),
                    order='sequence, name, id',
                    limit=section.max_items or 8,
                )
            payload['items'] = [
                self._serialize_category(category) for category in categories[: section.max_items]
            ]
        elif section.section_kind == 'featured_products':
            products = section.product_tmpl_ids
            if not products:
                products = self.env['product.template'].sudo().with_context(
                    website_id=website.id
                ).search(
                    website.sale_product_domain(),
                    order='publish_date desc, id desc',
                    limit=section.max_items or 8,
                )
            payload['items'] = [
                self._serialize_product(product, website) for product in products[: section.max_items]
            ]
        elif section.section_kind == 'content_page' and section.content_page_id:
            payload['items'] = [self._serialize_content_page(section.content_page_id)]

        return payload

    @api.model
    def _serialize_mobile_app(self, app, website):
        return {
            'id': app.id if app else False,
            'name': app.name if app else website.name,
            'app_code': app.app_code if app else 'main',
            'bundle_identifier': app.bundle_identifier if app else False,
            'package_name': app.package_name if app else False,
            'app_scheme': app.app_scheme if app else 'synthoshop',
            'return_url': (
                app.return_url
                if app and app.return_url
                else 'synthoshop://checkout/result'
            ),
            'logo_url': (
                self._image_url('mobile.ecommerce.app', app.id, 'logo') if app and app.logo else False
            ),
            'splash_image_url': (
                self._image_url('mobile.ecommerce.app', app.id, 'splash_image')
                if app and app.splash_image
                else False
            ),
            'primary_color': app.primary_color if app else '#C06E52',
            'accent_color': app.accent_color if app else '#142633',
            'minimum_supported_version': app.minimum_supported_version if app else False,
            'latest_version': app.latest_version if app else False,
            'force_update': bool(app and app.force_update),
            'maintenance_mode': bool(app and app.maintenance_mode),
            'maintenance_message': app.maintenance_message if app else False,
            'allow_guest_checkout': bool(not app or app.allow_guest_checkout),
            'wishlist_enabled': bool(not app or app.wishlist_enabled),
            'search_enabled': bool(not app or app.search_enabled),
            'version_notes': app.version_notes if app else False,
        }

    @api.model
    def _serialize_partner_address(self, partner):
        if not partner or not partner.id:
            return False

        return {
            'id': partner.id,
            'name': partner.name,
            'email': partner.email,
            'phone': partner.phone,
            'street': partner.street,
            'street2': partner.street2,
            'city': partner.city,
            'zip': partner.zip,
            'country_id': partner.country_id.id,
            'country_name': partner.country_id.name,
            'state_id': partner.state_id.id,
            'state_name': partner.state_id.name,
            'company_name': partner.company_name,
            'vat': partner.vat,
        }

    @api.model
    def _serialize_country(self, country):
        return {
            'id': country.id,
            'name': country.name,
            'code': country.code,
        }

    @api.model
    def _serialize_state(self, state):
        return {
            'id': state.id,
            'name': state.name,
            'code': state.code,
        }

    @api.model
    def _serialize_cart_line(self, line, website):
        product = line.product_id.product_tmpl_id
        return {
            'id': line.id,
            'product_tmpl_id': product.id,
            'product_id': line.product_id.id,
            'name': line.name,
            'quantity': line.product_uom_qty,
            'price_unit': line.price_unit,
            'subtotal': line.price_subtotal,
            'total': line.price_total,
            'currency': website.currency_id.name,
            'image_url': self._image_url('product.template', product.id),
            'is_delivery': bool(line.is_delivery),
        }

    @api.model
    def _serialize_order(self, order, website):
        lines = [
            self._serialize_cart_line(line, website)
            for line in order.order_line.filtered(
                lambda line: not line.display_type and line.product_id
            )
        ]
        return {
            'id': order.id,
            'name': order.name,
            'date_order': order.date_order.isoformat() if order.date_order else False,
            'state': order.state,
            'amount_total': order.amount_total,
            'amount_tax': order.amount_tax,
            'amount_untaxed': order.amount_untaxed,
            'currency': order.currency_id.name,
            'lines': lines,
        }

    @api.model
    def _serialize_delivery_method(self, order, carrier, amount=None):
        if amount is None and order and order.carrier_id == carrier:
            delivery_line = order.order_line.filtered('is_delivery')[:1]
            amount = delivery_line.price_total if delivery_line else 0.0
        amount = amount or 0.0
        return {
            'id': carrier.id,
            'name': carrier.name,
            'amount': amount,
            'currency': order.currency_id.name if order else self.env.company.currency_id.name,
            'selected': bool(order and order.carrier_id == carrier),
        }

    @api.model
    def _serialize_payment_option(self, provider, payment_method):
        return {
            'provider_id': provider.id,
            'provider_code': provider.code,
            'provider_name': provider.name,
            'payment_method_id': payment_method.id,
            'payment_method_code': payment_method.code,
            'payment_method_name': payment_method.name,
            'flow': 'redirect',
        }

    @api.model
    def get_home_payload(self, website_id=None, product_limit=8, category_limit=8):
        website = self._get_website(website_id)
        product_domain = website.sale_product_domain()
        category_domain = self.env['product.public.category']._get_available_category_domain(
            website.id
        )

        banners = self.env['mobile.ecommerce.banner'].sudo().search(
            [('active', '=', True), ('website_id', 'in', [False, website.id])],
            order='sequence, id',
            limit=5,
        )
        categories = self.env['product.public.category'].sudo().search(
            category_domain & Domain('parent_id', '=', False),
            order='sequence, name, id',
            limit=int(category_limit),
        )
        products = self.env['product.template'].sudo().with_context(website_id=website.id).search(
            product_domain,
            order='publish_date desc, id desc',
            limit=int(product_limit),
        )

        return {
            'website': {
                'id': website.id,
                'name': website.name,
                'currency': website.currency_id.name,
                'base_url': self._base_url(),
            },
            'banners': [self._serialize_banner(banner) for banner in banners],
            'categories': [self._serialize_category(category) for category in categories],
            'featured_products': [self._serialize_product(product, website) for product in products],
        }

    @api.model
    def get_bootstrap_payload(self, website_id=None):
        app, website = self._get_mobile_app(website_id)
        content_pages = app.content_page_ids.filtered('active') if app else self.env[
            'mobile.ecommerce.content.page'
        ]
        navigation_items = (
            app.navigation_item_ids.filtered('active') if app else self.env['mobile.ecommerce.navigation.item']
        )
        home_sections = app.home_section_ids.filtered('active') if app else self.env[
            'mobile.ecommerce.home.section'
        ]

        if not home_sections:
            fallback_home = self.get_home_payload(website_id=website.id)
            home_sections_payload = [
                {
                    'id': 'hero-banners',
                    'name': 'Hero Banners',
                    'section_key': 'hero_banners',
                    'title': 'Campaign banners',
                    'subtitle': '',
                    'section_kind': 'hero_banners',
                    'max_items': 5,
                    'items': fallback_home['banners'],
                },
                {
                    'id': 'featured-categories',
                    'name': 'Featured Categories',
                    'section_key': 'featured_categories',
                    'title': 'Shop by category',
                    'subtitle': '',
                    'section_kind': 'featured_categories',
                    'max_items': 8,
                    'items': fallback_home['categories'],
                },
                {
                    'id': 'featured-products',
                    'name': 'Featured Products',
                    'section_key': 'featured_products',
                    'title': 'Featured products',
                    'subtitle': '',
                    'section_kind': 'featured_products',
                    'max_items': 8,
                    'items': fallback_home['featured_products'],
                },
            ]
        else:
            home_sections_payload = [
                self._serialize_home_section(section, website)
                for section in home_sections.sorted(key=lambda record: (record.sequence, record.id))
            ]

        return {
            'website': {
                'id': website.id,
                'name': website.name,
                'currency': website.currency_id.name,
                'base_url': self._base_url(),
            },
            'app': self._serialize_mobile_app(app, website),
            'navigation': [
                self._serialize_navigation_item(item)
                for item in navigation_items.sorted(key=lambda record: (record.sequence, record.id))
            ],
            'home_sections': home_sections_payload,
            'content_pages': [
                self._serialize_content_page(page)
                for page in content_pages.sorted(key=lambda record: (record.sequence, record.id))
            ],
        }

    @api.model
    def search_products(
        self,
        website_id=None,
        search='',
        category_id=None,
        brand_id=None,
        limit=20,
        offset=0,
    ):
        website = self._get_website(website_id)
        domain = website.sale_product_domain()

        if search:
            domain &= Domain.OR([
                Domain('name', 'ilike', search),
                Domain('default_code', 'ilike', search),
                Domain('website_description', 'ilike', search),
                Domain('description_sale', 'ilike', search),
            ])
        if category_id:
            domain &= Domain('public_categ_ids', 'child_of', int(category_id))
        if brand_id and 'brand_id' in self.env['product.template']._fields:
            domain &= Domain('brand_id', '=', int(brand_id))

        products = self.env['product.template'].sudo().with_context(website_id=website.id).search(
            domain,
            order='name asc, id desc',
            limit=int(limit),
            offset=int(offset),
        )
        total = self.env['product.template'].sudo().with_context(
            website_id=website.id
        ).search_count(domain)

        return {
            'items': [self._serialize_product(product, website) for product in products],
            'total': total,
            'limit': int(limit),
            'offset': int(offset),
        }

    @api.model
    def get_product_detail(self, product_tmpl_id, website_id=None):
        website = self._get_website(website_id)
        domain = website.sale_product_domain() & Domain('id', '=', int(product_tmpl_id))
        product = self.env['product.template'].sudo().with_context(website_id=website.id).search(
            domain,
            limit=1,
        )
        if not product:
            return False

        product_payload = self._serialize_product(product, website)
        ratings = self.env['mobile.ecommerce.rating'].sudo().search(
            [('product_tmpl_id', '=', product.id)],
            limit=10,
        )
        product_payload.update({
            'checkout_url': f'{self._base_url()}/shop/cart',
            'ratings': [self._serialize_rating(rating) for rating in ratings],
        })
        return product_payload

    @api.model
    def get_brands_payload(self, website_id=None, limit=80, offset=0):
        website = self._get_website(website_id)
        if 'product.brand' not in self.env.registry:
            return {'items': [], 'total': 0, 'limit': int(limit), 'offset': int(offset)}

        brands = self.env['product.brand'].sudo().search(
            [],
            order='name, id',
            limit=int(limit),
            offset=int(offset),
        )
        return {
            'items': [self._serialize_brand(brand, website) for brand in brands],
            'total': self.env['product.brand'].sudo().search_count([]),
            'limit': int(limit),
            'offset': int(offset),
        }

    @api.model
    def get_wishlist_payload(self, partner, website_id=None):
        website = self._get_website(website_id)
        items = self.env['mobile.ecommerce.wishlist'].sudo().search([
            ('partner_id', '=', partner.commercial_partner_id.id),
        ])
        return {
            'items': [
                self._serialize_product(item.product_tmpl_id, website)
                for item in items
                if item.product_tmpl_id
            ],
            'product_ids': items.mapped('product_tmpl_id').ids,
            'total': len(items),
        }

    @api.model
    def get_cart_payload(self, order, website_id=None):
        website = self._get_website(website_id)
        if not order:
            return {
                'order_id': False,
                'cart_quantity': 0,
                'amount_untaxed': 0.0,
                'amount_tax': 0.0,
                'amount_total': 0.0,
                'currency': website.currency_id.name,
                'checkout_url': f'{self._base_url()}/shop/cart',
                'requires_delivery': False,
                'can_checkout': False,
                'lines': [],
            }

        return {
            'order_id': order.id,
            'cart_quantity': order.cart_quantity,
            'amount_untaxed': order.amount_untaxed,
            'amount_tax': order.amount_tax,
            'amount_total': order.amount_total,
            'currency': order.currency_id.name,
            'checkout_url': f'{self._base_url()}/shop/cart',
            'requires_delivery': order._has_deliverable_products(),
            'can_checkout': bool(order.website_order_line),
            'lines': [
                self._serialize_cart_line(line, website)
                for line in order.website_order_line.filtered(lambda line: line.product_id)
            ],
        }

    @api.model
    def get_checkout_state_payload(
        self,
        order,
        website,
        *,
        login_required=False,
        is_authenticated=False,
        billing_complete=False,
        shipping_complete=False,
        checkout_errors=None,
    ):
        checkout_errors = checkout_errors or []
        if not order:
            return {
                'order_id': False,
                'order_name': False,
                'access_token': False,
                'login_required': login_required,
                'is_authenticated': is_authenticated,
                'requires_delivery': False,
                'payment_required': False,
                'billing_complete': False,
                'shipping_complete': False,
                'billing_address': False,
                'shipping_address': False,
                'selected_delivery_method': False,
                'can_proceed_to_payment': False,
                'can_finalize_without_payment': False,
                'checkout_errors': checkout_errors,
                'cart': self.get_cart_payload(order, website.id),
            }

        is_anonymous = order._is_anonymous_cart()
        requires_delivery = order._has_deliverable_products()
        payment_required = bool(order.amount_total)
        selected_delivery_method = False
        if order.carrier_id:
            selected_delivery_method = self._serialize_delivery_method(order, order.carrier_id)

        return {
            'order_id': order.id,
            'order_name': order.name,
            'access_token': order._portal_ensure_token(),
            'login_required': login_required,
            'is_authenticated': is_authenticated,
            'requires_delivery': requires_delivery,
            'payment_required': payment_required,
            'billing_complete': billing_complete,
            'shipping_complete': shipping_complete or not requires_delivery,
            'billing_address': (
                False if is_anonymous else self._serialize_partner_address(order.partner_invoice_id)
            ),
            'shipping_address': (
                False if is_anonymous else self._serialize_partner_address(order.partner_shipping_id)
            ),
            'selected_delivery_method': selected_delivery_method,
            'can_proceed_to_payment': (
                not checkout_errors
                and (is_authenticated or not login_required)
                and billing_complete
                and (shipping_complete or not requires_delivery)
            ),
            'can_finalize_without_payment': (
                not checkout_errors
                and not payment_required
                and billing_complete
                and (shipping_complete or not requires_delivery)
            ),
            'checkout_errors': checkout_errors,
            'cart': self.get_cart_payload(order, website.id),
        }

    @api.model
    def get_address_schema_payload(
        self,
        country,
        address_type,
        *,
        countries,
        address_fields,
        required_fields,
    ):
        return {
            'address_type': address_type,
            'selected_country_id': country.id if country else False,
            'address_fields': address_fields,
            'required_fields': sorted(required_fields),
            'zip_before_city': (
                'zip' in address_fields
                and 'city' in address_fields
                and address_fields.index('zip') < address_fields.index('city')
            ),
            'phone_code': country.phone_code if country else False,
            'countries': [self._serialize_country(country_item) for country_item in countries],
            'states': [
                self._serialize_state(state) for state in (country.state_ids if country else [])
            ],
        }

    @api.model
    def get_delivery_methods_payload(self, order, methods):
        return {
            'items': methods,
            'selected_delivery_method': next(
                (method for method in methods if method['selected']),
                False,
            ),
            'order_id': order.id if order else False,
            'amount_total': order.amount_total if order else 0.0,
            'currency': (
                order.currency_id.name if order else self.env.company.currency_id.name
            ),
        }

    @api.model
    def get_payment_options_payload(self, order, options, errors=None):
        return {
            'items': options,
            'errors': errors or [],
            'order_id': order.id if order else False,
            'amount_total': order.amount_total if order else 0.0,
            'currency': (
                order.currency_id.name if order else self.env.company.currency_id.name
            ),
        }

    @api.model
    def get_payment_session_payload(
        self,
        *,
        order,
        tx,
        payment_page_url,
        return_url,
        access_token,
        status='pending',
    ):
        return {
            'tx_id': tx.id if tx else False,
            'order_id': order.id,
            'payment_page_url': payment_page_url,
            'return_url': return_url,
            'access_token': access_token,
            'status': status,
        }

    @api.model
    def get_payment_result_payload(
        self,
        *,
        order,
        tx=False,
        status,
        access_token=False,
        message=False,
    ):
        provider_message = False
        if tx and tx.state_message:
            provider_message = tx.state_message
        elif tx and tx.provider_id:
            provider_message = {
                'success': self._clean_text(tx.provider_id.done_msg),
                'pending': self._clean_text(tx.provider_id.pending_msg),
                'cancel': self._clean_text(tx.provider_id.cancel_msg),
            }.get(status, False)

        return {
            'order_id': order.id if order else False,
            'order_name': order.name if order else False,
            'order_state': order.state if order else False,
            'tx_id': tx.id if tx else False,
            'tx_state': tx.state if tx else False,
            'status': status,
            'access_token': access_token,
            'message': message or provider_message or False,
        }

    @api.model
    def lookup_barcode(self, barcode, website_id=None):
        website = self._get_website(website_id)
        if not barcode:
            return False

        # 1. Try product.product
        product = self.env['product.product'].sudo().search(
            [('barcode', '=', barcode)] + website.sale_product_domain(),
            limit=1,
        )
        if product:
            return self._serialize_product(product.product_tmpl_id, website)

        # 2. Try product.template
        product_tmpl = self.env['product.template'].sudo().search(
            [('barcode', '=', barcode)] + website.sale_product_domain(),
            limit=1,
        )
        if product_tmpl:
            return self._serialize_product(product_tmpl, website)

        # 3. Try product.packaging
        packaging = self.env['product.packaging'].sudo().search([('barcode', '=', barcode)], limit=1)
        if packaging and packaging.product_id:
            product = packaging.product_id
            if website.id in product.website_id.ids or not product.website_id:
                return self._serialize_product(product.product_tmpl_id, website)

        return False

    @api.model
    def toggle_wishlist(self, partner, product_tmpl_id, website_id=None):
        website = self._get_website(website_id)
        product_tmpl = self.env['product.template'].sudo().browse(int(product_tmpl_id)).exists()
        if not product_tmpl:
            return False

        wishlist_item = self.env['mobile.ecommerce.wishlist'].sudo().search([
            ('partner_id', '=', partner.commercial_partner_id.id),
            ('product_tmpl_id', '=', product_tmpl.id),
        ], limit=1)

        if wishlist_item:
            wishlist_item.unlink()
            added = False
        else:
            self.env['mobile.ecommerce.wishlist'].sudo().create({
                'partner_id': partner.commercial_partner_id.id,
                'product_tmpl_id': product_tmpl.id,
            })
            added = True

        return {
            'added': added,
            'wishlist': self.get_wishlist_payload(partner, website_id=website.id),
        }

    @api.model
    def rate_product(self, partner, product_tmpl_id, rating, review=None):
        product_tmpl = self.env['product.template'].sudo().browse(int(product_tmpl_id)).exists()
        if not product_tmpl:
            return False

        rating_val = str(int(rating))
        existing = self.env['mobile.ecommerce.rating'].sudo().search([
            ('partner_id', '=', partner.commercial_partner_id.id),
            ('product_tmpl_id', '=', product_tmpl.id),
        ], limit=1)

        if existing:
            existing.write({
                'rating': rating_val,
                'review': review,
                'date': fields.Datetime.now(),
            })
        else:
            self.env['mobile.ecommerce.rating'].sudo().create({
                'partner_id': partner.commercial_partner_id.id,
                'product_tmpl_id': product_tmpl.id,
                'rating': rating_val,
                'review': review,
            })
        return True

    @api.model
    def get_order_history(self, partner, website_id=None, limit=10):
        website = self._get_website(website_id)
        order_domain = [
            ('partner_id', 'child_of', partner.commercial_partner_id.id),
            ('website_id', '=', website.id),
            ('state', '!=', 'draft'),
        ]
        orders = self.env['sale.order'].sudo().search(
            order_domain,
            order='date_order desc, id desc',
            limit=int(limit),
        )
        return {
            'items': [self._serialize_order(order, website) for order in orders],
            'total': self.env['sale.order'].sudo().search_count(order_domain),
        }

    @api.model
    def get_account_payload(self, partner, website_id=None, order_limit=10):
        website = self._get_website(website_id)
        orders_payload = self.get_order_history(
            partner=partner,
            website_id=website.id,
            limit=order_limit,
        )
        return {
            'partner': {
                'id': partner.id,
                'name': partner.name,
                'email': partner.email,
                'phone': partner.phone,
            },
            'orders': orders_payload['items'],
            'orders_count': orders_payload['total'],
        }

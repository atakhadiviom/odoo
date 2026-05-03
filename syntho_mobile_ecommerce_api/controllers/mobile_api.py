import urllib.parse

from markupsafe import Markup
from werkzeug.exceptions import Forbidden, NotFound

from odoo import _, http
from odoo.addons.payment import utils as payment_utils
from odoo.addons.website_sale.controllers.main import WebsiteSale
from odoo.exceptions import AccessError, MissingError, ValidationError
from odoo.http import request


class MobileEcommerceApiController(WebsiteSale):

    def _service(self):
        return request.env['mobile.ecommerce.api']

    def _base_url(self):
        config = request.env['ir.config_parameter'].sudo()
        return (
            config.get_param('syntho_mobile_ecommerce_api.public_base_url')
            or config.get_param('mobile_ecommerce_app.public_base_url')
            or config.get_param('web.base.url', '')
        ).rstrip('/')

    def _ensure_ecommerce_access(self):
        if not request.website.has_ecommerce_access():
            raise Forbidden()

    def _get_checkout_order(self):
        order = request.cart
        if not order or order.state != 'draft' or not order.order_line:
            return request.env['sale.order']
        return order

    def _is_authenticated(self):
        return not request.env.user._is_public()

    def _login_required(self):
        return request.website.account_on_checkout == 'mandatory'

    def _format_error(self, title, message=False, code=False):
        payload = {'title': title}
        if message:
            payload['message'] = message
        if code:
            payload['code'] = code
        return payload

    def _serialize_error_pairs(self, errors):
        return [self._format_error(title, message) for title, message in errors]

    def _get_address_completion(self, order):
        if not order or not order.exists() or order._is_anonymous_cart():
            return False, False

        billing_partner = order.partner_invoice_id.sudo()
        shipping_partner = order.partner_shipping_id.sudo()
        billing_complete = bool(
            billing_partner and self._check_billing_address(billing_partner)
        )
        shipping_complete = bool(
            shipping_partner and self._check_delivery_address(shipping_partner)
        )
        return billing_complete, shipping_complete

    def _get_checkout_errors(self, order):
        if not order or not order.exists():
            return [
                self._format_error(
                    _("Your cart is empty."),
                    _("Add at least one product before starting checkout."),
                    code='empty_cart',
                ),
            ]

        errors = []
        if self._login_required() and not self._is_authenticated():
            errors.append(
                self._format_error(
                    _("Sign in required."),
                    _("This website requires a customer account before checkout can continue."),
                    code='login_required',
                )
            )
        errors.extend(self._serialize_error_pairs(self._get_shop_payment_errors(order)))
        return errors

    def _get_checkout_state_payload(self, order):
        website = request.website
        billing_complete, shipping_complete = self._get_address_completion(order)
        return self._service().get_checkout_state_payload(
            order,
            website,
            login_required=self._login_required(),
            is_authenticated=self._is_authenticated(),
            billing_complete=billing_complete,
            shipping_complete=shipping_complete,
            checkout_errors=self._get_checkout_errors(order),
        )

    def _get_payment_values(self, order):
        if not order or not order.exists():
            return {}
        order._recompute_cart()
        return self._get_shop_payment_values(order)

    def _get_redirect_payment_options(self, order):
        if not order or not order.exists():
            return [], []

        payment_values = self._get_payment_values(order)
        errors = self._serialize_error_pairs(payment_values.get('errors', []))
        providers_sudo = payment_values.get('providers_sudo', request.env['payment.provider'])
        payment_methods_sudo = payment_values.get(
            'payment_methods_sudo', request.env['payment.method']
        )

        options = []
        for provider_sudo in providers_sudo:
            if not provider_sudo._get_redirect_form_view():
                continue
            provider_payment_methods = payment_methods_sudo.filtered(
                lambda payment_method: provider_sudo in payment_method.provider_ids
            )
            if not provider_payment_methods and provider_sudo.payment_method_ids:
                provider_payment_methods = provider_sudo.payment_method_ids
            for payment_method_sudo in provider_payment_methods:
                options.append(
                    self._service()._serialize_payment_option(
                        provider_sudo,
                        payment_method_sudo,
                    )
                )
        return options, errors

    def _get_mobile_return_url(self, explicit_return_url=False):
        if explicit_return_url:
            return explicit_return_url.strip()

        config = request.env['ir.config_parameter'].sudo()
        return (
            config.get_param('syntho_mobile_ecommerce_api.return_url')
            or config.get_param('mobile_ecommerce_app.return_url')
            or 'synthoshop://checkout/result'
        ).strip()

    def _append_query_params(self, url, params):
        split_url = urllib.parse.urlsplit(url)
        query_params = dict(urllib.parse.parse_qsl(split_url.query, keep_blank_values=True))
        for key, value in params.items():
            if value in (None, False, ''):
                continue
            query_params[key] = value
        return urllib.parse.urlunsplit((
            split_url.scheme,
            split_url.netloc,
            split_url.path,
            urllib.parse.urlencode(query_params, doseq=True),
            split_url.fragment,
        ))

    def _get_order_access_token(self, order):
        return order._portal_ensure_token()

    def _get_tx_access_token(self, tx):
        return payment_utils.generate_access_token(tx.partner_id.id, tx.amount, tx.currency_id.id)

    def _build_mobile_landing_route(self, order, tx):
        return self._append_query_params(
            '/mobile_api/checkout/payment_return',
            {
                'order_id': order.id,
                'access_token': self._get_order_access_token(order),
                'tx_id': tx.id,
                'tx_access_token': self._get_tx_access_token(tx),
            },
        )

    def _build_payment_page_url(self, order, tx):
        path = self._append_query_params(
            f'/mobile_api/checkout/payment_page/{tx.id}',
            {
                'order_id': order.id,
                'access_token': self._get_order_access_token(order),
            },
        )
        return f'{self._base_url()}{path}'

    def _build_quotation_payment_url(self, order):
        if hasattr(order, 'get_portal_url'):
            portal_url = order.get_portal_url()
        else:
            portal_url = f'/my/orders/{order.id}'
        portal_url = self._append_query_params(
            portal_url,
            {'access_token': self._get_order_access_token(order)},
        )
        if portal_url.startswith(('http://', 'https://')):
            return portal_url
        return f'{self._base_url()}{portal_url}'

    def _build_mobile_deep_link(
        self,
        order,
        tx=False,
        *,
        status,
        return_url=False,
        message=False,
    ):
        return self._append_query_params(
            self._get_mobile_return_url(return_url),
            {
                'order_id': order.id if order else False,
                'tx_id': tx.id if tx else False,
                'status': status,
                'access_token': self._get_order_access_token(order) if order else False,
                'message': message or False,
            },
        )

    def _check_order_access(self, order_id, access_token):
        try:
            return self._document_check_access(
                'sale.order',
                int(order_id),
                access_token=access_token,
            )
        except (AccessError, MissingError):
            raise NotFound()

    def _check_tx_access(self, tx_id, tx_access_token=False):
        tx = request.env['payment.transaction'].sudo().browse(int(tx_id)).exists()
        if not tx:
            raise NotFound()
        if tx_access_token and not payment_utils.check_access_token(
            tx_access_token,
            tx.partner_id.id,
            tx.amount,
            tx.currency_id.id,
        ):
            raise NotFound()
        return tx

    def _get_order_transaction(self, order, tx_id=False, tx_access_token=False):
        if tx_id:
            tx = self._check_tx_access(tx_id, tx_access_token=tx_access_token)
        else:
            tx = order.get_portal_last_transaction()
        if not tx:
            return request.env['payment.transaction']
        if 'sale_order_ids' in tx._fields and order not in tx.sale_order_ids:
            raise NotFound()
        return tx

    def _map_payment_status(self, order, tx=False, explicit_status=False):
        if explicit_status in {'cancel', 'error'}:
            return explicit_status
        if order and order.state == 'sale':
            return 'success'
        if not tx:
            return 'pending' if order and order.exists() else 'error'
        return {
            'done': 'success',
            'authorized': 'pending',
            'pending': 'pending',
            'cancel': 'cancel',
            'error': 'error',
            'draft': 'pending',
        }.get(tx.state, 'pending')

    def _maybe_reset_sale_session(self, order):
        if not order:
            return
        active_order_id = request.session.get('sale_order_id')
        last_order_id = request.session.get('sale_last_order_id')
        if order.id in {active_order_id, last_order_id}:
            request.website.sale_reset()
            request.session['sale_last_order_id'] = order.id

    @http.route(
        '/mobile_api/bootstrap',
        type='jsonrpc',
        auth='public',
        website=True,
        methods=['POST'],
    )
    def mobile_bootstrap(self):
        self._ensure_ecommerce_access()
        return self._service().get_bootstrap_payload()

    @http.route(
        '/mobile_api/home',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_home(self, website_id=None, product_limit=8, category_limit=8):
        self._ensure_ecommerce_access()
        return self._service().get_home_payload(
            website_id=website_id,
            product_limit=product_limit,
            category_limit=category_limit,
        )

    @http.route(
        '/mobile_api/products',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_products(
        self,
        website_id=None,
        search='',
        category_id=None,
        brand_id=None,
        limit=20,
        offset=0,
    ):
        self._ensure_ecommerce_access()
        return self._service().search_products(
            website_id=website_id,
            search=search,
            category_id=category_id,
            brand_id=brand_id,
            limit=limit,
            offset=offset,
        )

    @http.route(
        '/mobile_api/product',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_product(self, product_tmpl_id, website_id=None):
        self._ensure_ecommerce_access()
        product_payload = self._service().get_product_detail(
            product_tmpl_id=product_tmpl_id,
            website_id=website_id,
        )
        if not product_payload:
            raise NotFound()
        return product_payload

    @http.route(
        '/mobile_api/brands',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_brands(self, website_id=None, limit=80, offset=0):
        self._ensure_ecommerce_access()
        return self._service().get_brands_payload(
            website_id=website_id,
            limit=limit,
            offset=offset,
        )

    @http.route(
        '/mobile_api/products/by_brand',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_products_by_brand(self, brand_id, website_id=None, limit=20, offset=0):
        self._ensure_ecommerce_access()
        return self._service().search_products(
            website_id=website_id,
            brand_id=brand_id,
            limit=limit,
            offset=offset,
        )

    def _find_product_by_barcode(self, barcode):
        barcode = (barcode or '').strip()
        if not barcode:
            return request.env['product.template']

        product_product = request.env['product.product'].sudo()
        if 'barcode' in product_product._fields:
            variant = product_product.search([('barcode', '=', barcode)], limit=1)
            if variant:
                return variant.product_tmpl_id

        product_template = request.env['product.template'].sudo()
        if 'barcode' in product_template._fields:
            template = product_template.search([('barcode', '=', barcode)], limit=1)
            if template:
                return template

        if 'product.packaging' in request.env.registry:
            packaging_model = request.env['product.packaging'].sudo()
            if 'barcode' in packaging_model._fields:
                packaging = packaging_model.search([('barcode', '=', barcode)], limit=1)
                if packaging:
                    if 'product_id' in packaging._fields and packaging.product_id:
                        return packaging.product_id.product_tmpl_id
                    if 'product_tmpl_id' in packaging._fields and packaging.product_tmpl_id:
                        return packaging.product_tmpl_id

        return request.env['product.template']

    @http.route(
        '/mobile_api/products/barcode',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_product_by_barcode(self, barcode, website_id=None):
        self._ensure_ecommerce_access()
        product = self._find_product_by_barcode(barcode)
        if not product:
            raise NotFound()
        product_payload = self._service().get_product_detail(
            product_tmpl_id=product.id,
            website_id=website_id,
        )
        if not product_payload:
            raise NotFound()
        return product_payload

    @http.route(
        '/mobile_api/cart',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_cart(self, website_id=None):
        self._ensure_ecommerce_access()
        return self._service().get_cart_payload(request.cart, website_id=website_id)

    @http.route(
        '/mobile_api/cart/add',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def mobile_cart_add(self, product_id, quantity=1.0, website_id=None):
        self._ensure_ecommerce_access()
        order = request.cart or request.website._create_cart()
        result = order.with_context(skip_cart_verification=True)._cart_add(
            product_id=int(product_id),
            quantity=float(quantity),
        )
        order._verify_cart_after_update()
        payload = self._service().get_cart_payload(order, website_id=website_id)
        payload['last_operation'] = result
        return payload

    @http.route(
        '/mobile_api/cart/update',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def mobile_cart_update(self, line_id, quantity, website_id=None):
        self._ensure_ecommerce_access()
        order = request.cart
        if not order:
            return self._service().get_cart_payload(order, website_id=website_id)

        result = order.with_context(skip_cart_verification=True)._cart_update_line_quantity(
            line_id=int(line_id),
            quantity=float(quantity),
        )
        order._verify_cart_after_update()
        payload = self._service().get_cart_payload(order, website_id=website_id)
        payload['last_operation'] = result
        return payload

    @http.route(
        '/mobile_api/wishlist',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_wishlist(self, website_id=None):
        self._ensure_ecommerce_access()
        return self._service().get_wishlist_payload(
            request.env.user.partner_id,
            website_id=website_id,
        )

    @http.route(
        '/mobile_api/wishlist/toggle',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
    )
    def mobile_wishlist_toggle(self, product_id, website_id=None):
        self._ensure_ecommerce_access()
        product = request.env['product.template'].sudo().browse(int(product_id)).exists()
        if not product:
            raise NotFound()

        partner = request.env.user.partner_id.commercial_partner_id
        wishlist_model = request.env['mobile.ecommerce.wishlist'].sudo()
        wishlist_item = wishlist_model.search([
            ('partner_id', '=', partner.id),
            ('product_tmpl_id', '=', product.id),
        ], limit=1)
        wished = False
        if wishlist_item:
            wishlist_item.unlink()
        else:
            wishlist_model.create({
                'partner_id': partner.id,
                'product_tmpl_id': product.id,
            })
            wished = True

        payload = self._service().get_wishlist_payload(partner, website_id=website_id)
        payload.update({
            'product_id': product.id,
            'wished': wished,
        })
        return payload

    @http.route(
        '/mobile_api/product/rate',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
    )
    def mobile_product_rate(self, product_id, rating, review='', website_id=None):
        self._ensure_ecommerce_access()
        product = request.env['product.template'].sudo().browse(int(product_id)).exists()
        if not product:
            raise NotFound()
        rating_value = int(rating)
        if rating_value < 1 or rating_value > 5:
            raise ValidationError(_("Rating must be between 1 and 5."))

        partner = request.env.user.partner_id.commercial_partner_id
        rating_model = request.env['mobile.ecommerce.rating'].sudo()
        rating_record = rating_model.search([
            ('partner_id', '=', partner.id),
            ('product_tmpl_id', '=', product.id),
        ], limit=1)
        values = {
            'partner_id': partner.id,
            'product_tmpl_id': product.id,
            'rating': str(rating_value),
            'review': review or '',
        }
        if rating_record:
            rating_record.write(values)
        else:
            rating_model.create(values)
        return self._service().get_product_detail(product.id, website_id=website_id)

    @http.route(
        '/mobile_api/checkout/state',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def checkout_state(self):
        self._ensure_ecommerce_access()
        return self._get_checkout_state_payload(self._get_checkout_order())

    @http.route(
        '/mobile_api/checkout/address_schema',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def checkout_address_schema(self, address_type='billing', country_id=None):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        partner = order.partner_invoice_id if address_type == 'billing' else order.partner_shipping_id
        country = request.env['res.country'].sudo().browse(
            int(country_id) if country_id else partner.country_id.id
        ).exists()
        if not country:
            country = (
                request.env.user.partner_id.country_id
                or request.website.company_id.partner_id.country_id
                or request.env['res.country'].sudo().search([], limit=1)
            )

        address_fields = country.get_address_fields() if country else ['street', 'city', 'zip']
        if address_type == 'delivery':
            required_fields = self._get_mandatory_delivery_address_fields(country)
        else:
            required_fields = self._get_mandatory_billing_address_fields(country)

        return self._service().get_address_schema_payload(
            country,
            address_type,
            countries=request.env['res.country'].sudo().search([]),
            address_fields=address_fields,
            required_fields=required_fields,
        )

    @http.route(
        '/mobile_api/checkout/address_upsert',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def checkout_address_upsert(
        self,
        values,
        address_type='billing',
        partner_id=False,
        use_delivery_as_billing=False,
    ):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        if not order:
            raise ValidationError(_("Your cart is empty."))
        if self._login_required() and not self._is_authenticated():
            state_payload = self._get_checkout_state_payload(order)
            state_payload.update({
                'success': False,
                'partner_id': False,
                'invalid_fields': [],
                'messages': [
                    _(
                        "This website requires you to sign in before creating a checkout address."
                    )
                ],
            })
            return state_payload

        partner_sudo, address_type = self._prepare_address_update(
            order,
            partner_id=partner_id and int(partner_id),
            address_type=address_type,
        )
        is_new_address = not partner_sudo
        callback = '/shop/checkout?try_skip_step=true' if (is_new_address or order.only_services) else '/shop/checkout'

        partner_sudo, feedback_dict = self._create_or_update_address(
            partner_sudo,
            address_type=address_type,
            use_delivery_as_billing=use_delivery_as_billing,
            callback=callback,
            order_sudo=order,
            **(values or {}),
        )

        if feedback_dict.get('invalid_fields'):
            state_payload = self._get_checkout_state_payload(order)
            state_payload.update({
                'success': False,
                'partner_id': partner_sudo.id if partner_sudo else False,
                'invalid_fields': feedback_dict.get('invalid_fields', []),
                'messages': feedback_dict.get('messages', []),
            })
            return state_payload

        was_anonymous_cart = order._is_anonymous_cart()
        is_main_address = was_anonymous_cart or order.partner_id.id == partner_sudo.id
        partner_fields = set()
        if is_main_address:
            partner_fields.add('partner_id')
        if address_type == 'billing':
            partner_fields.add('partner_invoice_id')
            if use_delivery_as_billing:
                partner_fields.add('partner_shipping_id')
            if is_new_address and order.only_services:
                partner_fields.add('partner_shipping_id')
        elif address_type == 'delivery':
            partner_fields.add('partner_shipping_id')
            if use_delivery_as_billing:
                partner_fields.add('partner_invoice_id')
        order._update_address(partner_sudo.id, partner_fields)
        if was_anonymous_cart:
            order.message_unsubscribe(order.website_id.partner_id.ids)

        state_payload = self._get_checkout_state_payload(order)
        state_payload.update({
            'success': True,
            'partner_id': partner_sudo.id,
            'invalid_fields': [],
            'messages': feedback_dict.get('messages', []),
        })
        return state_payload

    @http.route(
        '/mobile_api/checkout/delivery_methods',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def checkout_delivery_methods(self):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        if not order:
            return self._service().get_delivery_methods_payload(
                request.env['sale.order'],
                [],
            )
        methods = []
        if order._has_deliverable_products():
            for delivery_method in order._get_delivery_methods():
                rate = delivery_method.rate_shipment(order)
                if not rate.get('success'):
                    continue
                methods.append(
                    self._service()._serialize_delivery_method(
                        order,
                        delivery_method,
                        amount=rate.get('price'),
                    )
                )
        return self._service().get_delivery_methods_payload(order, methods)

    @http.route(
        '/mobile_api/checkout/delivery_select',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def checkout_delivery_select(self, carrier_id):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        if not order:
            raise ValidationError(_("Your cart is empty."))
        carrier_id = int(carrier_id)
        available_methods = order._get_delivery_methods()
        delivery_method = available_methods.filtered(lambda carrier: carrier.id == carrier_id)
        if not delivery_method:
            raise ValidationError(_("The selected delivery method is not available anymore."))
        rate = delivery_method.rate_shipment(order)
        if not rate.get('success'):
            raise ValidationError(rate.get('error_message') or _("Shipping is unavailable."))
        order._set_delivery_method(delivery_method, rate=rate)
        return self._get_checkout_state_payload(order)

    @http.route(
        '/mobile_api/checkout/payment_options',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def checkout_payment_options(self):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        if not order:
            return self._service().get_payment_options_payload(
                request.env['sale.order'],
                [],
                errors=self._get_checkout_errors(order),
            )
        state_payload = self._get_checkout_state_payload(order)
        if not state_payload['can_proceed_to_payment'] and not state_payload['can_finalize_without_payment']:
            return self._service().get_payment_options_payload(
                order,
                [],
                errors=state_payload['checkout_errors'],
            )
        options, errors = self._get_redirect_payment_options(order)
        if order.amount_total:
            options.insert(0, self._service()._serialize_quotation_payment_option(order))
        if not options and order.amount_total:
            errors = errors or [
                self._format_error(
                    _("No compatible payment option is available."),
                    _("Enable at least one redirect-based provider for this website."),
                    code='no_payment_option',
                )
            ]
        return self._service().get_payment_options_payload(
            order,
            options,
            errors=[] if options else errors,
        )

    @http.route(
        '/mobile_api/checkout/payment_session',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def checkout_payment_session(self, provider_id=None, payment_method_id=None, return_url=False):
        self._ensure_ecommerce_access()
        order = self._get_checkout_order()
        if not order:
            raise ValidationError(_("Your cart is empty."))

        state_payload = self._get_checkout_state_payload(order)
        if not (
            state_payload['can_proceed_to_payment'] or state_payload['can_finalize_without_payment']
        ):
            raise ValidationError(
                state_payload['checkout_errors'][0]['message']
                if state_payload['checkout_errors']
                else _("Checkout is not ready yet.")
            )

        order_access_token = self._get_order_access_token(order)
        mobile_return_url = self._get_mobile_return_url(return_url)
        if not order.amount_total:
            order._check_cart_is_ready_to_be_paid()
            order._validate_order()
            self._maybe_reset_sale_session(order)
            return self._service().get_payment_session_payload(
                order=order,
                tx=False,
                payment_page_url=False,
                return_url=mobile_return_url,
                access_token=order_access_token,
                status='success',
            )

        payment_options, errors = self._get_redirect_payment_options(order)

        provider_id = int(provider_id)
        payment_method_id = int(payment_method_id)
        if provider_id == 0 and payment_method_id == 0:
            return self._service().get_payment_session_payload(
                order=order,
                tx=False,
                payment_page_url=self._build_quotation_payment_url(order),
                return_url=mobile_return_url,
                access_token=order_access_token,
                status='pending',
            )

        if errors and not payment_options:
            raise ValidationError(errors[0].get('message') or errors[0].get('title'))

        selected_option = next(
            (
                option for option in payment_options
                if option['provider_id'] == provider_id
                and option['payment_method_id'] == payment_method_id
            ),
            False,
        )
        if not selected_option:
            raise ValidationError(_("The selected payment option is no longer available."))

        partner_sudo = request.env.user.partner_id if self._is_authenticated() else order.partner_invoice_id
        tx = self._create_transaction(
            provider_id=provider_id,
            payment_method_id=payment_method_id,
            token_id=None,
            amount=order.amount_total,
            currency_id=order.currency_id.id,
            partner_id=partner_sudo.id,
            flow='redirect',
            tokenization_requested=False,
            landing_route='/mobile_api/checkout/payment_return',
            custom_create_values={'sale_order_ids': [(6, 0, [order.id])]},
            sale_order_id=order.id,
        )
        tx.sudo().landing_route = self._build_mobile_landing_route(order, tx)

        return self._service().get_payment_session_payload(
            order=order,
            tx=tx,
            payment_page_url=self._build_payment_page_url(order, tx),
            return_url=mobile_return_url,
            access_token=order_access_token,
            status='pending',
        )

    @http.route(
        '/mobile_api/checkout/payment_status',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def checkout_payment_status(self, order_id, access_token, tx_id=False):
        self._ensure_ecommerce_access()
        order = self._check_order_access(order_id, access_token)
        tx = self._get_order_transaction(order, tx_id=tx_id)
        status = self._map_payment_status(order, tx)
        if status == 'success':
            self._maybe_reset_sale_session(order)
        return self._service().get_payment_result_payload(
            order=order,
            tx=tx,
            status=status,
            access_token=self._get_order_access_token(order),
        )

    @http.route(
        '/mobile_api/checkout/payment_page/<int:tx_id>',
        type='http',
        auth='public',
        website=True,
        sitemap=False,
    )
    def checkout_payment_page(self, tx_id, order_id, access_token, **kwargs):
        self._ensure_ecommerce_access()
        order = self._check_order_access(order_id, access_token)
        tx = self._get_order_transaction(order, tx_id=tx_id)
        status = self._map_payment_status(order, tx)
        if status == 'success':
            self._maybe_reset_sale_session(order)
            return request.redirect(self._build_mobile_deep_link(order, tx, status=status))
        if tx.state not in {'draft', 'pending'}:
            return request.redirect(self._build_mobile_landing_route(order, tx))

        processing_values = tx._get_processing_values()
        redirect_form_html = processing_values.get('redirect_form_html')
        if not redirect_form_html:
            return request.redirect(
                self._build_mobile_landing_route(order, tx)
            )

        return request.render(
            'syntho_mobile_ecommerce_api.mobile_payment_page',
            {
                'order': order,
                'tx': tx,
                'provider': tx.provider_id,
                'redirect_form_html': Markup(redirect_form_html),
                'cancel_url': self._append_query_params(
                    '/mobile_api/checkout/payment_return',
                    {
                        'order_id': order.id,
                        'access_token': self._get_order_access_token(order),
                        'tx_id': tx.id,
                        'tx_access_token': self._get_tx_access_token(tx),
                        'status': 'cancel',
                    },
                ),
            },
        )

    @http.route(
        '/mobile_api/checkout/payment_return',
        type='http',
        auth='public',
        website=True,
        sitemap=False,
    )
    def checkout_payment_return(
        self,
        order_id,
        access_token,
        tx_id=False,
        tx_access_token=False,
        status=False,
        message=False,
        return_url=False,
        **kwargs,
    ):
        self._ensure_ecommerce_access()
        order = self._check_order_access(order_id, access_token)
        tx = self._get_order_transaction(order, tx_id=tx_id, tx_access_token=tx_access_token)
        resolved_status = self._map_payment_status(order, tx, explicit_status=status)
        if resolved_status == 'success':
            self._maybe_reset_sale_session(order)
        return request.redirect(
            self._build_mobile_deep_link(
                order,
                tx,
                status=resolved_status,
                return_url=return_url,
                message=message or (tx.state_message if tx else False),
            )
        )

    @http.route(
        '/mobile_api/auth/google',
        type='jsonrpc',
        auth='none',
        methods=['POST'],
        csrf=False,
    )
    def mobile_auth_google(self, token):
        user, error = self._service().authenticate_google(token)
        if error:
            return self._format_error("Authentication Failed", error)

        # Log the user in
        request.session.authenticate(request.db, user.login, user.password)
        return self._service().get_account_payload(user.partner_id)

    @http.route(
        '/mobile_api/account',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_account(self, website_id=None, order_limit=10):
        return self._service().get_account_payload(
            request.env.user.partner_id,
            website_id=website_id,
            order_limit=order_limit,
        )

    @http.route(
        '/mobile_api/orders',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_orders(self, website_id=None, limit=10):
        return self._service().get_order_history(
            request.env.user.partner_id,
            website_id=website_id,
            limit=limit,
        )

    @http.route(
        '/mobile_api/wishlist',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_wishlist(self, website_id=None):
        return self._service().get_wishlist_payload(
            request.env.user.partner_id,
            website_id=website_id,
        )

    @http.route(
        '/mobile_api/wishlist/toggle',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
    )
    def mobile_wishlist_toggle(self, product_tmpl_id=None, product_id=None, website_id=None):
        self._ensure_ecommerce_access()
        product_tmpl_id = product_tmpl_id or product_id
        if not product_tmpl_id:
            raise ValidationError(_("Missing product for wishlist."))
        return self._service().toggle_wishlist(
            request.env.user.partner_id,
            product_tmpl_id,
            website_id=website_id,
        )

    @http.route(
        '/mobile_api/device/register',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
    )
    def mobile_device_register(self, token, platform):
        partner = request.env.user.partner_id if self._is_authenticated() else False
        return self._service().register_device(partner, token, platform)

    @http.route(
        '/mobile_api/notifications',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_notifications(self, limit=30, unread_only=False):
        self._ensure_ecommerce_access()
        return self._service().get_notifications_payload(
            request.env.user.partner_id,
            limit=limit,
            unread_only=unread_only,
        )

    @http.route(
        '/mobile_api/notifications/read',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
    )
    def mobile_notifications_read(self, notification_ids=None):
        self._ensure_ecommerce_access()
        return self._service().mark_notifications_read(
            request.env.user.partner_id,
            notification_ids=notification_ids,
        )

    @http.route(
        '/mobile_api/product/rate',
        type='jsonrpc',
        auth='user',
        methods=['POST'],
        website=True,
    )
    def mobile_product_rate(self, product_tmpl_id, rating, review=None):
        return self._service().rate_product(
            request.env.user.partner_id,
            product_tmpl_id,
            rating,
            review=review,
        )

    @http.route(
        '/mobile_api/products/by_brand',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_products_by_brand(self, brand_id, website_id=None, limit=20, offset=0):
        self._ensure_ecommerce_access()
        return self._service().search_products(
            website_id=website_id,
            brand_id=brand_id,
            limit=limit,
            offset=offset,
        )

    @http.route(
        '/mobile_api/brands',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_brands(self, website_id=None, limit=80, offset=0):
        self._ensure_ecommerce_access()
        return self._service().get_brands_payload(
            website_id=website_id,
            limit=limit,
            offset=offset,
        )

    @http.route(
        '/mobile_api/products/barcode',
        type='jsonrpc',
        auth='public',
        methods=['POST'],
        website=True,
        readonly=True,
    )
    def mobile_products_barcode(self, barcode, website_id=None):
        self._ensure_ecommerce_access()
        result = self._service().lookup_barcode(barcode, website_id=website_id)
        if not result:
            raise NotFound()
        return result

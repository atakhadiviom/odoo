from odoo import fields, models


class MobileEcommerceApp(models.Model):
    _name = 'mobile.ecommerce.app'
    _description = 'Mobile Ecommerce App'
    _order = 'sequence, id'

    name = fields.Char(required=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    website_id = fields.Many2one('website', string='Website')
    app_code = fields.Char(required=True, default='main')
    bundle_identifier = fields.Char()
    package_name = fields.Char()
    app_scheme = fields.Char(default='synthoshop')
    return_url = fields.Char(default='synthoshop://checkout/result')
    logo = fields.Image()
    splash_image = fields.Image()
    primary_color = fields.Char(default='#C06E52')
    accent_color = fields.Char(default='#142633')
    minimum_supported_version = fields.Char()
    latest_version = fields.Char()
    force_update = fields.Boolean()
    maintenance_mode = fields.Boolean()
    maintenance_message = fields.Text(
        default='The app is briefly unavailable while we finish an update.'
    )
    allow_guest_checkout = fields.Boolean(default=True)
    wishlist_enabled = fields.Boolean(default=True)
    search_enabled = fields.Boolean(default=True)
    version_notes = fields.Text()
    home_section_ids = fields.One2many(
        'mobile.ecommerce.home.section',
        'app_id',
        string='Home Sections',
    )
    navigation_item_ids = fields.One2many(
        'mobile.ecommerce.navigation.item',
        'app_id',
        string='Navigation Items',
    )
    content_page_ids = fields.One2many(
        'mobile.ecommerce.content.page',
        'app_id',
        string='Content Pages',
    )


class MobileEcommerceHomeSection(models.Model):
    _name = 'mobile.ecommerce.home.section'
    _description = 'Mobile Ecommerce Home Section'
    _order = 'sequence, id'

    name = fields.Char(required=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    app_id = fields.Many2one('mobile.ecommerce.app', required=True, ondelete='cascade')
    section_key = fields.Char()
    title = fields.Char(required=True)
    subtitle = fields.Char()
    section_kind = fields.Selection(
        [
            ('hero_banners', 'Hero Banners'),
            ('featured_categories', 'Featured Categories'),
            ('featured_products', 'Featured Products'),
            ('content_page', 'Content Page'),
        ],
        required=True,
        default='featured_products',
    )
    max_items = fields.Integer(default=8)
    banner_ids = fields.Many2many('mobile.ecommerce.banner', string='Banners')
    category_ids = fields.Many2many('product.public.category', string='Categories')
    product_tmpl_ids = fields.Many2many('product.template', string='Products')
    content_page_id = fields.Many2one('mobile.ecommerce.content.page', string='Content Page')


class MobileEcommerceNavigationItem(models.Model):
    _name = 'mobile.ecommerce.navigation.item'
    _description = 'Mobile Ecommerce Navigation Item'
    _order = 'sequence, id'

    name = fields.Char(required=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    app_id = fields.Many2one('mobile.ecommerce.app', required=True, ondelete='cascade')
    label = fields.Char(required=True)
    icon = fields.Char(
        help='Free-form icon token for the mobile app, such as home, shop, cart, or person.'
    )
    target_kind = fields.Selection(
        [
            ('tab', 'Tab'),
            ('category', 'Category'),
            ('content_page', 'Content Page'),
            ('url', 'External URL'),
        ],
        required=True,
        default='tab',
    )
    tab_key = fields.Selection(
        [
            ('home', 'Home'),
            ('shop', 'Shop'),
            ('cart', 'Cart'),
            ('account', 'Account'),
        ],
        default='home',
    )
    category_id = fields.Many2one('product.public.category', string='Category')
    content_page_id = fields.Many2one('mobile.ecommerce.content.page', string='Content Page')
    external_url = fields.Char()


class MobileEcommerceContentPage(models.Model):
    _name = 'mobile.ecommerce.content.page'
    _description = 'Mobile Ecommerce Content Page'
    _order = 'sequence, id'

    name = fields.Char(required=True)
    sequence = fields.Integer(default=10)
    active = fields.Boolean(default=True)
    app_id = fields.Many2one('mobile.ecommerce.app', required=True, ondelete='cascade')
    page_key = fields.Selection(
        [
            ('about', 'About'),
            ('faq', 'FAQ'),
            ('terms', 'Terms'),
            ('privacy', 'Privacy'),
            ('contact', 'Contact'),
            ('custom', 'Custom'),
        ],
        default='custom',
        required=True,
    )
    slug = fields.Char(required=True)
    title = fields.Char(required=True)
    summary = fields.Text()
    cover_image = fields.Image()
    body_html = fields.Html(required=True)

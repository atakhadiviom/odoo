"""Seed a polished SynthoShop mobile demo.

Run inside Odoo with:
    odoo shell -d <db> < syntho_mobile_ecommerce_api/demo/seed_mobile_demo.py
"""

from __future__ import annotations

import base64
from io import BytesIO

from PIL import Image, ImageDraw, ImageFont


def png_data(size, background, title, subtitle='', accent='#142633'):
    width, height = size
    image = Image.new('RGB', (width, height), background)
    draw = ImageDraw.Draw(image)
    font_title = ImageFont.load_default()
    font_subtitle = ImageFont.load_default()

    for offset in range(0, width, 28):
        color = tuple(max(0, channel - 14) for channel in background)
        draw.line((offset, height, offset + height // 2, 0), fill=color, width=2)

    draw.rounded_rectangle(
        (24, 24, width - 24, height - 24),
        radius=28,
        fill=tuple(min(255, channel + 20) for channel in background),
        outline=accent,
        width=4,
    )
    draw.rounded_rectangle(
        (width - 175, 40, width - 48, height - 40),
        radius=26,
        fill=accent,
    )
    draw.rectangle((width - 146, 65, width - 76, height - 65), fill='white')
    draw.rounded_rectangle((width - 137, 78, width - 85, height - 78), radius=8, fill=background)
    draw.ellipse((width - 119, height - 88, width - 103, height - 72), fill=accent)

    draw.text((54, 58), title, fill=accent, font=font_title)
    if subtitle:
        draw.text((54, 94), subtitle, fill=accent, font=font_subtitle)

    output = BytesIO()
    image.save(output, format='PNG')
    return base64.b64encode(output.getvalue())


def find_product(names):
    Product = env['product.template'].sudo()
    for name in names:
        product = Product.search([('name', 'ilike', name)], limit=1)
        if product:
            return product
    return Product.search([('sale_ok', '=', True)], limit=1)


website = env['website'].sudo().search([], limit=1)
config = env['ir.config_parameter'].sudo()
config.set_param('web.base.url', 'http://127.0.0.1:8069')
config.set_param('syntho_mobile_ecommerce_api.public_base_url', 'http://127.0.0.1:8123')

App = env['mobile.ecommerce.app'].sudo()
app = App.search([('app_code', '=', 'main')], limit=1)
app_values = {
    'name': 'SynthoShop Demo',
    'sequence': 1,
    'active': True,
    'website_id': website.id,
    'app_code': 'main',
    'bundle_identifier': 'com.syntho.shop.demo',
    'package_name': 'com.syntho.shop.demo',
    'app_scheme': 'synthoshop',
    'return_url': 'synthoshop://checkout/result',
    'primary_color': '#00A09D',
    'accent_color': '#142633',
    'minimum_supported_version': '0.1.0',
    'latest_version': '0.1.0',
    'allow_guest_checkout': True,
    'wishlist_enabled': True,
    'search_enabled': True,
    'version_notes': 'Demo storefront with brands, barcode lookup, wishlist, ratings, and checkout.',
    'logo': png_data((256, 256), (0, 160, 157), 'Syntho', 'Shop', '#FFFFFF'),
    'splash_image': png_data((900, 1200), (245, 241, 232), 'SynthoShop', 'Odoo 19 mobile commerce'),
}
if app:
    app.write(app_values)
else:
    app = App.create(app_values)

Category = env['product.public.category'].sudo()
category_specs = [
    ('Mobile Deals', 'Fresh picks for the demo storefront', (0, 160, 157)),
    ('Work From Home', 'Desks, chairs, and everyday productivity gear', (192, 110, 82)),
    ('Office Essentials', 'Default Odoo products arranged for shopping', (20, 38, 51)),
    ('Storage & Organization', 'Cabinets, boxes, and tidy workspace helpers', (235, 184, 88)),
]
categories = {}
for sequence, (name, description, color) in enumerate(category_specs, 1):
    category = Category.search([('name', '=', name)], limit=1)
    values = {
        'name': name,
        'sequence': sequence,
        'website_description': description,
        'cover_image': png_data((512, 320), color, name, description),
    }
    if category:
        category.write(values)
    else:
        category = Category.create(values)
    categories[name] = category

Brand = env['product.brand'].sudo()
brand_specs = [
    ('Odoo Office', 'Ergonomic everyday office products.', (0, 160, 157)),
    ('Odoo Desks', 'Flexible desks and work surfaces.', (192, 110, 82)),
    ('Odoo Storage', 'Storage and organization essentials.', (20, 38, 51)),
    ('Odoo Demo Picks', 'Curated products for the mobile app demo.', (235, 184, 88)),
]
brands = {}
for name, description, color in brand_specs:
    brand = Brand.search([('name', '=', name)], limit=1)
    values = {
        'name': name,
        'description': description,
        'logo': png_data((256, 256), color, name.split()[-1], 'SynthoShop'),
    }
    if brand:
        brand.write(values)
    else:
        brand = Brand.create(values)
    brands[name] = brand

product_specs = [
    (['Office Chair', 'Chair'], 'Odoo Office', 'Work From Home', '40164785534101', 4),
    (['Office Lamp', 'Lamp'], 'Odoo Office', 'Office Essentials', '40164785534112', 5),
    (['Customizable Desk', 'Desk'], 'Odoo Desks', 'Work From Home', '40164785534123', 5),
    (['Large Desk', 'Desk'], 'Odoo Desks', 'Mobile Deals', '40164785534134', 4),
    (['Cabinet', 'Storage'], 'Odoo Storage', 'Storage & Organization', '40164785534145', 4),
    (['Storage Box', 'Box'], 'Odoo Storage', 'Storage & Organization', '40164785534156', 5),
    (['Pedal Bin', 'Bin'], 'Odoo Storage', 'Office Essentials', '40164785534167', 4),
    (['Conference Chair', 'Chair'], 'Odoo Demo Picks', 'Mobile Deals', '40164785534178', 5),
]
featured_products = env['product.template'].sudo()
for names, brand_name, category_name, barcode, rating in product_specs:
    product = find_product(names)
    if not product:
        continue
    values = {
        'website_published': True,
        'sale_ok': True,
        'public_categ_ids': [(4, categories[category_name].id)],
    }
    website_copy = (
        f'<p>{product.description_sale or product.name}</p>'
        f'<p>Explore this {category_name.lower()} item directly from the Odoo website catalog. '
        'The mobile app now uses the same ecommerce description customers see online.</p>'
    )
    if 'description_ecommerce' in product._fields:
        values['description_ecommerce'] = website_copy
    if 'website_description' in product._fields:
        values['website_description'] = website_copy
    if 'brand_id' in product._fields:
        values['brand_id'] = brands[brand_name].id
    product.write(values)
    variant = product.product_variant_id
    if 'barcode' in variant._fields:
        variant.barcode = barcode
    featured_products |= product

partner = env.user.partner_id.sudo()
Rating = env['mobile.ecommerce.rating'].sudo()
for product in featured_products:
    if Rating.search([('product_tmpl_id', '=', product.id), ('partner_id', '=', partner.id)], limit=1):
        continue
    Rating.create({
        'product_tmpl_id': product.id,
        'partner_id': partner.id,
        'rating': '5',
        'review': 'Demo review: clean product page, quick cart flow, and ready for mobile checkout.',
    })

for product in env['product.template'].sudo().search([('website_published', '=', True)]):
    existing_website_copy = (
        product.description_ecommerce
        if 'description_ecommerce' in product._fields
        else False
    ) or product.website_description
    if existing_website_copy:
        continue
    fallback_copy = product.description_sale or product.name
    website_copy = (
        f'<p>{fallback_copy}</p>'
        '<p>This website description is shared with the mobile storefront, so customers see the same '
        'product story in the app and on the Odoo ecommerce site.</p>'
    )
    values = {}
    if 'description_ecommerce' in product._fields:
        values['description_ecommerce'] = website_copy
    if 'website_description' in product._fields:
        values['website_description'] = website_copy
    if values:
        product.write(values)

Banner = env['mobile.ecommerce.banner'].sudo()
banner_specs = [
    ('Hero - Mobile Deals', 1, 'Mobile deals are live', 'Tap into Odoo products from a native storefront.', (0, 160, 157), 'category', False, categories['Mobile Deals']),
    ('Hero - Work From Home', 2, 'Build your work setup', 'Desks, chairs, lamps, and storage from the default catalog.', (192, 110, 82), 'category', False, categories['Work From Home']),
    ('Hero - Checkout Ready', 3, 'Checkout inside the app', 'Review cart, address, delivery, then pay through hosted Odoo payment.', (20, 38, 51), 'product', featured_products[:1], False),
]
banner_records = env['mobile.ecommerce.banner'].sudo()
for name, sequence, title, subtitle, color, action_kind, product, category in banner_specs:
    banner = Banner.search([('name', '=', name)], limit=1)
    values = {
        'name': name,
        'sequence': sequence,
        'active': True,
        'website_id': website.id,
        'title': title,
        'subtitle': subtitle,
        'image': png_data((1200, 540), color, title, subtitle),
        'action_kind': action_kind,
        'product_tmpl_id': product.id if product else False,
        'category_id': category.id if category else False,
        'external_url': False,
    }
    if banner:
        banner.write(values)
    else:
        banner = Banner.create(values)
    banner_records |= banner

Page = env['mobile.ecommerce.content.page'].sudo()
page_specs = [
    ('About SynthoShop', 1, 'about', 'about-synthoshop', 'About SynthoShop', 'A demo mobile commerce app controlled from Odoo.', '<h2>Native mobile commerce for Odoo 19</h2><p>SynthoShop demonstrates a mobile storefront whose banners, sections, navigation, brands, wishlist, ratings, cart, and checkout are managed by Odoo.</p>'),
    ('FAQ', 2, 'faq', 'faq', 'FAQ', 'Answers for the demo mobile app.', '<h2>FAQ</h2><p>Use the Shop tab to browse Odoo products, Brands to filter by brand, Scan to test barcode lookup, and Cart to start checkout.</p>'),
    ('Contact', 3, 'contact', 'contact', 'Contact', 'Demo contact details.', '<h2>Contact</h2><p>Email demo@synthoerp.com or use Odoo backend settings to customize this page.</p>'),
]
pages = {}
for name, sequence, page_key, slug, title, summary, body_html in page_specs:
    page = Page.search([('app_id', '=', app.id), ('slug', '=', slug)], limit=1)
    values = {
        'name': name,
        'sequence': sequence,
        'active': True,
        'app_id': app.id,
        'page_key': page_key,
        'slug': slug,
        'title': title,
        'summary': summary,
        'cover_image': png_data((900, 420), (245, 241, 232), title, summary),
        'body_html': body_html,
    }
    if page:
        page.write(values)
    else:
        page = Page.create(values)
    pages[slug] = page

Nav = env['mobile.ecommerce.navigation.item'].sudo()
for item in Nav.search([('app_id', '=', app.id)]):
    item.unlink()
nav_specs = [
    ('Home', 1, 'home', 'home'),
    ('Shop', 2, 'shop', 'shop'),
    ('Cart', 3, 'cart', 'cart'),
    ('Account', 4, 'account', 'account'),
]
for label, sequence, icon, tab_key in nav_specs:
    Nav.create({
        'name': f'Demo {label}',
        'sequence': sequence,
        'active': True,
        'app_id': app.id,
        'label': label,
        'icon': icon,
        'target_kind': 'tab',
        'tab_key': tab_key,
    })

Section = env['mobile.ecommerce.home.section'].sudo()
for section in Section.search([('app_id', '=', app.id)]):
    section.unlink()
Section.create({
    'name': 'Demo Hero Banners',
    'sequence': 1,
    'active': True,
    'app_id': app.id,
    'section_key': 'hero_banners',
    'title': 'Featured campaigns',
    'subtitle': 'Odoo-controlled mobile content',
    'section_kind': 'hero_banners',
    'max_items': 3,
    'banner_ids': [(6, 0, banner_records.ids)],
})
Section.create({
    'name': 'Demo Categories',
    'sequence': 2,
    'active': True,
    'app_id': app.id,
    'section_key': 'featured_categories',
    'title': 'Shop by category',
    'subtitle': 'Mobile-ready category tiles',
    'section_kind': 'featured_categories',
    'max_items': 4,
    'category_ids': [(6, 0, [category.id for category in categories.values()])],
})
Section.create({
    'name': 'Demo Featured Products',
    'sequence': 3,
    'active': True,
    'app_id': app.id,
    'section_key': 'featured_products',
    'title': 'Demo products',
    'subtitle': 'Default Odoo products enriched for mobile',
    'section_kind': 'featured_products',
    'max_items': 8,
    'product_tmpl_ids': [(6, 0, featured_products.ids)],
})
Section.create({
    'name': 'Demo About Page',
    'sequence': 4,
    'active': True,
    'app_id': app.id,
    'section_key': 'content_page_about',
    'title': 'Controlled from Odoo',
    'subtitle': 'Backend-managed content page',
    'section_kind': 'content_page',
    'max_items': 1,
    'content_page_id': pages['about-synthoshop'].id,
})

env.cr.commit()
print(
    'Seeded SynthoShop demo: '
    f'{len(banner_records)} banners, {len(categories)} categories, '
    f'{len(featured_products)} products, {len(brands)} brands.'
)

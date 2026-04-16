# SynthoShop Flutter App

Flutter mobile storefront for the `syntho_mobile_ecommerce_api` Odoo 19 addon.

## Features

- Odoo-managed home layout, banners, colors, navigation, and maintenance mode.
- Catalog, category filtering, product detail, cart, native checkout, and hosted payment return handling.
- Brand browsing through `/mobile_api/brands`.
- Barcode lookup through `/mobile_api/products/barcode`.
- Authenticated wishlist and product review submission.

## Local Web Run

From the repository root:

```bash
cd flutter_app
/Users/atakhadivi/development/flutter/bin/flutter pub get
/Users/atakhadivi/development/flutter/bin/flutter build web --no-tree-shake-icons --no-wasm-dry-run \
  --dart-define=ODOO_BASE_URL=http://127.0.0.1:8123 \
  --dart-define=ODOO_DATABASE=syntho_mobile_ecommerce_20260415 \
  --dart-define=ODOO_RETURN_URL=synthoshop://checkout/result
python3 scripts/local_web_proxy.py
```

Open `http://127.0.0.1:8123`.

## Mobile Build Defines

Use these values for Android/iOS builds:

```bash
flutter run \
  --dart-define=ODOO_BASE_URL=https://your-odoo-domain.com \
  --dart-define=ODOO_DATABASE=your_database \
  --dart-define=ODOO_RETURN_URL=synthoshop://checkout/result
```

## Deep Link

The default app scheme is `synthoshop://`. Payment returns are expected at:

```text
synthoshop://checkout/result
```

Configure the same value in Odoo using:

```text
syntho_mobile_ecommerce_api.return_url
```

## App Icon

The launcher icon source is:

```text
assets/branding/app_icon.png
```

Regenerate launcher icons after dependency install:

```bash
dart run flutter_launcher_icons
```

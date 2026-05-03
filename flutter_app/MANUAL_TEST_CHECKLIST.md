# SynthoShop Manual Test Checklist

Use this file while testing the local Flutter web app against the local Odoo 19 Docker instance.

## Local Test URLs

- App preview: http://127.0.0.1:8123/
- Odoo backend: http://127.0.0.1:8069/
- Expected database: `syntho_mobile_ecommerce_20260415`
- Demo login: `admin`
- Demo password: `admin`

## Before Testing

1. Start Docker Desktop.
2. From the repo root, start Odoo:

   ```bash
   docker compose -f docker-compose.odoo.yml up -d
   ```

3. From `flutter_app`, start the local web proxy:

   ```bash
   python3 -u scripts/local_web_proxy.py
   ```

4. Open http://127.0.0.1:8123/ in a browser.
5. Hard refresh the browser once if icons or stale content appear.

## Home Screen

- Confirm the app title reads from Odoo company data, for example `My Company`.
- Confirm the round logo beside the title loads from the Odoo company logo.
- Confirm the subtitle reads from the Odoo website name, for example `My Website`.
- Confirm the top wishlist and cart icons render as real vector icons, not square missing-glyph boxes.
- Confirm the hero banner appears as a slider with visible pagination dots.
- Swipe or wait for the hero slider and confirm it changes slides.
- Tap a hero slide and confirm it navigates to the expected product, category, or shop target when configured.
- Confirm categories appear as round image tiles from website categories.
- Tap each category tile and confirm Shop opens filtered to that category.
- Use the search bar with a term such as `desk` and confirm Shop opens with matching results.
- Confirm the bottom navigation only shows `Home`, `Shop`, `Cart`, and `Account`.
- Confirm bottom navigation icons are distinct and correct: home, shop/store, cart, account.

## Shop And Product Discovery

- Open `Shop` from the bottom navigation.
- Confirm product images load from Odoo.
- Confirm product names, prices, category labels, and rating summaries display.
- Tap a product card and confirm Product Detail opens.
- Confirm search and category filters do not crash or show stale results.

## Product Detail

- Confirm the back button renders as an arrow icon, not a missing-glyph square.
- Confirm the product image loads.
- Confirm the product name, price, category, and rating summary are visible.
- Confirm the Description section uses the website/ecommerce product description from Odoo.
- Confirm star icons render correctly.
- Tap Add to Cart and confirm the cart count/state updates.
- If signed in, tap the wishlist heart and confirm it toggles.

## Account And Login

- Open `Account`.
- Login with `admin` / `admin`.
- Confirm login succeeds and does not show `Session expired`.
- Confirm the account screen shows the logged-in user, for example `Administrator`.
- Confirm order/profile sections render without errors.

## Cart

- Add at least one product to the cart.
- Open `Cart`.
- Confirm the product line, price, quantity, subtotal, and total display.
- Change quantity and confirm totals update after sync.
- Remove an item and confirm the cart updates.
- Confirm empty cart messaging appears when the cart has no products.

## Checkout Smoke Test

- From a cart with at least one product, start checkout.
- Confirm Review opens with current cart totals.
- Confirm Address screen loads existing partner data when signed in.
- Confirm Delivery screen lists available Odoo carriers when configured.
- Confirm Delivery screen shows the current shipping country and any carrier country restrictions from Odoo.
- Confirm Payment screen lists compatible Odoo payment providers when configured.
- Confirm Payment screen selects `Pay on Odoo quotation` by default.
- Tap `Open Odoo quotation` and confirm the in-app browser opens the Odoo quotation/order portal for payment.
- After returning from the in-app browser, confirm the app checks Odoo payment status instead of trusting the browser result.
- Do not trust browser return state alone: after payment return or cancel, confirm the app resolves status from Odoo.

## Regression Checks

- No missing-glyph square icons should appear anywhere.
- No repeated Noto missing-font warnings should appear from app icons.
- No `Unexpected token '<'` JSON errors should appear.
- No `false: type 'bool' is not a subtype of type 'int?'` startup errors should appear.
- Product detail should not fail with `XMLHttpRequest error` when Odoo and the proxy are running.
- Browser refresh should keep the app usable.

## Feedback Notes

When giving feedback, please include:

- Screen name.
- What you tapped.
- What you expected.
- What happened.
- Screenshot if possible.
- Browser console error text if visible.

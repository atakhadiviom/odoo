# Syntho Shop Mobile App

This is a React Native / Expo storefront app scaffold for Odoo 19.

## What it uses

- Odoo built-in session login via `/web/session/authenticate`
- Custom mobile endpoints from `syntho_mobile_ecommerce_api`
- A lightweight Expo client with no navigation framework dependency

## Configure

Copy `.env.example` to `.env` and set:

- `EXPO_PUBLIC_ODOO_BASE_URL`
- `EXPO_PUBLIC_ODOO_DB`
- `EXPO_PUBLIC_ODOO_RETURN_URL`

For a physical device, do not use `localhost`; use your machine's LAN URL instead.
The default return URL is `synthoshop://checkout/result`, which matches the Expo app scheme
configured in `app.json`.

## Run

```bash
cd mobile_app
npm install
npx expo start
```

## Current MVP scope

- Home feed
- Category browsing
- Product detail
- Guest cart
- Customer login
- Account summary and order history
- Native checkout review, address, delivery, and payment-option steps
- Hosted Odoo payment page opened in an in-app browser
- Deep-link return back into the checkout result screen

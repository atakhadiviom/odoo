# Handoff: Odoo Ecommerce Flutter App

> **For Claude Code developers** — This package contains wireframe design references created in HTML. Your task is to implement these designs inside the existing Flutter codebase at `flutter_app/lib/`. Do **not** ship the HTML directly — use it as a structural and behavioral spec, and apply the existing Flutter theme (`app_theme.dart`) for all styling.

---

## Overview

`syntho_shop_flutter` is a customer-facing Flutter ecommerce app connecting to an Odoo 19 backend via JSON-RPC. The wireframes cover 5 primary screens and the full checkout flow. All screens use a shared bottom navigation bar with 5 tabs.

**Fidelity:** Low-fidelity wireframes — structure, layout, and flow are defined. Apply the existing design system (colors, border radius, card styles) from `app_theme.dart` for all final styling.

---

## Design Tokens (from `app_theme.dart`)

| Token | Value | Usage |
|---|---|---|
| `primary` | `#C65D3D` | CTAs, active states, prices, accent text |
| `secondary` / `ink` | `#182126` | Headlines, icons, dark surfaces |
| `background` | `#FBF9F7` | Scaffold background |
| `surface` | `#FFFFFF` | Cards, inputs |
| `outlineVariant` | `#E5DED5` | Card borders, dividers |
| `star / rating` | `#F5A623` | Star ratings |
| Card `borderRadius` | `20px` | All cards |
| Button `borderRadius` | `16px` | ElevatedButton |
| Input `borderRadius` | `16px` | TextField |
| Button padding | `24px H × 16px V` | ElevatedButton |
| Screen padding | `20px H, 8px T, 32px B` | ListView padding |

---

## Screen 1 — Home (`home_screen.dart`)

**Purpose:** Landing feed. Shows hero banners, category chips, and featured products.

### Layout (top → bottom)
```
AppBar
  - Left: App name "syntho shop" (titleLarge, fontWeight 700)
  - Right: Barcode icon + Cart icon (32×32 IconButtons)

SearchBar
  - Full width, 14px border radius
  - Placeholder: "Search products…"
  - Leading search icon

ListView (padding: 20px H, 8px T, 32px B)
  ├── HeroCard                          ← HeroCard widget (common.dart)
  │     height: ~180px, full width
  │     Card with image + overlay text (title + subtitle)
  │     Taps → onSelectProduct() or onOpenCategory()
  │
  ├── SectionTitle "Shop by category"
  ├── Wrap of ActionChip (spacing: 12px)
  │     Each chip → onOpenCategory(category.id)
  │
  ├── SectionTitle "Featured products"
  └── List of ProductCard (spacing: 16px bottom)
        Each card → onSelectProduct(product.id)
        Wishlist heart icon (filled if wishlisted)
```

### ProductCard (`product_card.dart`)
- Row layout: 64×64 image | name + price + wishlist heart
- Card border: `outlineVariant` at 50% opacity
- Price: `primary` color, fontWeight 700
- Wishlist: `Icons.favorite` / `Icons.favorite_border` in `primary`

### Key interactions
| Action | Handler |
|---|---|
| Tap banner | `onSelectProduct(id)` or `onOpenCategory(id)` |
| Tap category chip | `onOpenCategory(category.id)` |
| Tap product card | `onSelectProduct(product.id)` |
| Tap wishlist heart | `appState.toggleWishlist(product.id)` (requires sign-in) |
| Pull to refresh | `appState.refreshBootstrap()` + `appState.refreshHome()` |

---

## Screen 2 — Catalog (`catalog_screen.dart`)

**Purpose:** Browse products within a category. Supports filtering and sorting.

### Layout
```
AppBar
  - Title: category name
  - Trailing: grid/list toggle icon + filter icon

SearchBar (scoped to category)

Filter chips row (horizontal scroll)
  - "Brand", "Price ↑", "New", etc.
  - Active chip: primary border + tinted background

GridView (2 columns, spacing: 10px)
  └── ProductCard (compact)
        - Image (aspect ratio 1:1, full width)
        - Name (13px, fontWeight 600)
        - Price (13px, primary)
        - Wishlist icon (top-right overlay)
```

### Key interactions
| Action | Handler |
|---|---|
| Tap product | `onSelectProduct(product.id)` |
| Tap filter chip | Update sort/filter state, re-fetch products |
| Toggle grid/list | Local UI state |

---

## Screen 3 — Product Detail (`product_detail_screen.dart`)

**Purpose:** Full product page. Image, description, variants, reviews, add-to-cart CTA.

### Layout
```
AppBar (transparent)
  - Leading: back chevron
  - Trailing: wishlist heart (primary color)

ListView (padding: 20px H, 8px T, 40px B)
  ├── Hero image card
  │     AspectRatio 1:1, borderRadius 20px, elevation 8
  │     Uses Hero tag: 'product_{id}'
  │
  ├── Row: product name (left) + price (right)
  │     name: headlineSmall, fontWeight 900
  │     price: headlineSmall, fontWeight 900, primary color
  │
  ├── Brand name (titleSmall, primary, bold)     [if present]
  ├── _RatingSummary (stars + "X.X from N reviews")  [if rated]
  ├── Category name chips (primary color, bold, 13px)
  │
  ├── SectionTitle "Description"
  ├── Description text (bodyLarge, height 1.6, onSurfaceVariant)
  │
  ├── Variant chips (if applicable)
  │     ActionChip per variant (color / size)
  │
  └── _ReviewPanel (Card, padding 18px)
        - Existing reviews (take 3): name + stars + review text
        - Divider
        - Star rating selector (1–5 IconButtons, #F5A623)
        - TextField (3 lines, "Share what you liked…")
        - Submit button (ElevatedButton.icon)

Sticky bottom CTA (position above home indicator)
  ElevatedButton.icon
    icon: Icons.add_shopping_cart_rounded
    label: "Add to cart"
    height: 60px, full width
    loading state: CircularProgressIndicator (white, strokeWidth 2)
```

### Key interactions
| Action | Handler |
|---|---|
| Tap wishlist | `appState.toggleWishlist(product.id)` |
| Tap "Add to cart" | `appState.addToCart(product.variantId)` → SnackBar confirmation |
| Submit review | `appState.api.rateProduct(id, rating, review)` → refresh product |
| Error | `showDialog` AlertDialog with title + message + OK |

---

## Screen 4 — Cart & Checkout (`checkout_flow_screen.dart`)

**Purpose:** 4-step checkout flow managed by a single stateful screen.

### Step Indicator (always visible at top)
```
[1 Review] ——— [2 Address] ——— [3 Delivery] ——— [4 Payment]
```
- Active step: filled `primary` circle, bold label
- Completed: semi-transparent `primary`
- Upcoming: `#ddd` grey

---

### Step 1 — Review (`CheckoutStep.review`)
```
SectionTitle "Review order items"
List of cart lines (Card + ListTile):
  - leading: 56×56 image (borderRadius 12px)
  - title: product name (bold)
  - subtitle: "Quantity: N"
  - trailing: formatted price (primary, bold)

CheckoutErrorList (if errors)
SummaryPanel (Card):
  - Subtotal, Shipping, Tax, Total rows
  - Total row: bold, primary color

ElevatedButton "Continue to address" (full width, 56px height)
  - Disabled if cart is empty
```

### Step 2 — Address (`CheckoutStep.address`)
```
SectionTitle "Contact and shipping details"
MessageCard (if checkout messages)

AddressFormCard "Billing address"
  Fields (from AddressSchema):
    Full name, Email, Phone, Street, Street 2,
    City, ZIP, Country (dropdown), State (dropdown)

SwitchListTile "Use billing address for shipping"
  [if requiresDelivery && !useBillingForShipping]
  → Show second AddressFormCard "Shipping address"

ElevatedButton "Continue to delivery" / "Saving details…"
```

### Step 3 — Delivery (`CheckoutStep.delivery`)
```
SectionTitle "Choose delivery method"
List of RadioListTile per carrier:
  - value: method.id
  - title: method.name (bold)
  - subtitle: formatted price (currency + amount)
  - Selecting a method calls API immediately

ElevatedButton "Continue to payment"
  - Disabled until a method is selected
```

### Step 4 — Payment (`CheckoutStep.payment`)
```
SectionTitle "Select payment provider"
List of RadioListTile per payment option:
  - value: "${providerId}:${paymentMethodId}"
  - title: paymentMethodName (bold)
  - subtitle: providerName

ElevatedButton "Pay securely" / "Confirm order" (if no payment required)
  loading states: "Initializing…" / "Verifying…"
```

### Result screen (`CheckoutStep.result`)
```
Card (padding 32px) centered:
  Icon (64px): check_circle / hourglass / error_outline
  Headline: "Payment successful!" / "Payment is pending" / "Payment failed"
  Message text
  Summary box (grey surface):
    Order name | Order state | Transaction state
  ElevatedButton "Return to cart"
  TextButton "Check status again" (if pending)
```

### Key state variables
| Variable | Type | Purpose |
|---|---|---|
| `_step` | `CheckoutStep` | Controls which step panel renders |
| `_checkoutState` | `CheckoutState?` | Cart lines, addresses, flags |
| `_billingForm` / `_shippingForm` | `CheckoutAddressInput` | Form data |
| `_useBillingForShipping` | `bool` | Toggle separate shipping address |
| `_selectedPaymentKey` | `String?` | `"providerId:paymentMethodId"` |
| `_pendingSession` | `PaymentSession?` | Tracks in-progress payment |

---

## Screen 5 — Account (`account_screen.dart`)

**Purpose:** User profile, order history, wishlist, barcode scanner, settings.

### Layout
```
AppBar: "My Account"

Avatar row (60×60 circle + name + email)

ListView sections:
  ├── "My Orders"
  │     List of order rows: order name + status → chevron
  │
  ├── "Wishlist"
  │     Horizontal scroll of ProductCard (compact)
  │     Heart icon to remove → appState.toggleWishlist(id)
  │
  ├── "Scan barcode"
  │     Tappable card → navigate to barcode_screen.dart
  │     Uses mobile_scanner package
  │
  └── "Settings"
        Addresses → navigate to address management
        Notifications → toggle
        Sign out → appState.signOut()
```

---

## Navigation Structure (`app_shell.dart`)

```
Scaffold
  body: IndexedStack (preserves scroll position per tab)
    [0] HomeScreen
    [1] CatalogScreen
    [2] CheckoutFlowScreen   ← also used as Cart tab
    [3] WishlistScreen
    [4] AccountScreen

  bottomNavigationBar: NavigationBar (Material 3)
    items: Home | Shop | Cart (badge) | Saved | Account
    selectedIndex: _currentIndex
    onDestinationSelected: setState → _currentIndex
```

### Cart badge
- Show `appState.cartCount` as a badge on the Cart tab icon
- Use `Badge` widget wrapping `Icons.shopping_bag_outlined`

---

## Bottom Navigation Icons
| Index | Label | Icon (outlined) | Icon (filled) |
|---|---|---|---|
| 0 | Home | `Icons.home_outlined` | `Icons.home` |
| 1 | Shop | `Icons.grid_view_outlined` | `Icons.grid_view` |
| 2 | Cart | `Icons.shopping_bag_outlined` | `Icons.shopping_bag` |
| 3 | Saved | `Icons.favorite_border` | `Icons.favorite` |
| 4 | Account | `Icons.person_outline` | `Icons.person` |

---

## API Service (`odoo_api.dart`) — Key Methods

| Method | Purpose |
|---|---|
| `getProduct(templateId)` | Fetch full product detail |
| `getCheckoutState()` | Load cart + checkout status |
| `upsertCheckoutAddress(values, type)` | Save billing/shipping address |
| `getDeliveryMethods()` | List available carriers |
| `selectDeliveryMethod(carrierId)` | Set delivery method on order |
| `getPaymentOptions()` | List payment providers |
| `createPaymentSession(providerId, methodId)` | Initiate payment → returns URL |
| `getPaymentStatus(orderId, token, txId)` | Poll for payment result |
| `rateProduct(productId, rating, review)` | Submit a product review |

---

## App State (`app_state.dart`) — Key Properties

| Property | Type | Purpose |
|---|---|---|
| `home` | `HomePayload?` | Banners + categories + featured products |
| `bootstrap` | `BootstrapPayload?` | Managed home sections |
| `cartCount` | `int` | Badge count on Cart tab |
| `wishlistIds` | `Set<int>` | Product IDs in wishlist |
| `account` | `Account?` | `null` = guest user |

---

## Loading & Error Patterns
- **Loading:** `CircularProgressIndicator()` centered
- **Error:** `RetryState` widget (from `common.dart`) — title + optional message + retry button
- **Empty:** `MessageCard` widget — title + message
- **Success:** `SnackBar` with `SnackBarBehavior.floating`, `borderRadius 12px`
- **Error dialog:** `AlertDialog` with title + content + "OK" TextButton

---

## Files in This Package

| File | Purpose |
|---|---|
| `README.md` | This document — full implementation spec |
| `Wireframes.html` | Interactive wireframes — open in browser to explore all 5 screens |

---

## Suggested Implementation Order

1. **Verify theme** — confirm `buildAppTheme()` is wired in `main.dart`
2. **Bottom nav** — implement `app_shell.dart` with `IndexedStack` + cart badge
3. **Home screen** — `HeroCard` + category chips + `ProductCard` list
4. **Catalog screen** — 2-col `GridView` + filter chips
5. **Product detail** — image Hero + sticky CTA + review panel
6. **Checkout flow** — step indicator + 4 step panels + result screen
7. **Account screen** — profile header + orders + wishlist + barcode

---

*Generated from wireframes — April 2026. Source repo: `atakhadiviom/odoo` branch `codex/odoo-ecommerce-mobile-app`.*

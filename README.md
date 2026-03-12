# Custom Odoo Modules

This repository contains custom Odoo modules that follow the [Odoo Apps Vendor Guidelines](https://apps.odoo.com/apps/vendor-guidelines).

## Odoo Apps Vendor Guidelines Summary

To ensure quality and maintain service standards for users, any module added to this repository must adhere to the following guidelines:

### 1. Application Manifest (`__manifest__.py`)
- **Name:** Must be explicit and contain no more than 25 characters. Avoid adjectives or company names.
- **Version:** Must follow major-minor-bugfix semantics including the Odoo version (e.g., `19.0.1.0.0`). Modules in beta should use a version inferior to 1.0.
- **License:** Should be compatible with its dependencies. Recommended licenses are `LGPL-3` for open-source apps and `OPL-1` for proprietary apps.
- **Dependencies:** The `depends` list must contain all existing dependencies to avoid repository scan errors.
- **Optional fields:** `summary`, `live_test_url`, `price`, `currency` (EUR or USD), and `support` email.

### 2. Description Page (`static/description/index.html`)
- The description and screenshots must be in **English**.
- No promotions, advertisements, or links to external app stores.
- Features must be accurate and not misleading.
- You can use external canonical YouTube links, `mailto:`, and `skype:` prefixes.
- **No static tags, widgets, modals, or injected JavaScript.** Use Bootstrap 4 classes for styling.

### 3. Pricing & Support
- If sold externally, the price on the Odoo Apps store must be equal to or lower than other platforms.
- By publishing on Odoo Apps, you agree to their customer refund policy and must provide support for paid apps.

### 4. Features & App Completeness
- Apps should be as bug-free and complete as possible.
- Provide a detailed, accurate list of features. No hidden or undocumented functionalities.
- Your app must not break the Odoo Enterprise Subscription Agreement (e.g., altering validity checks or internal/portal functionalities).
- The module must be installable simply by copying it into the `addons` folder. Avoid complex install scripts.

### 5. Data and User Protection
- Transparently declare what customer data is collected or sent externally.
- **No vendor lock-in:** The app cannot require an activation key to run.
- You must develop your own code unless contributing to the open-source community under a permissive license. No plagiarism or cloning Enterprise modules.
- Malicious apps (e.g., those stealing data, modifying hidden files, containing obfuscated code) are strictly forbidden.

### 6. Scoring of Apps
Every app page on the Odoo Apps store is scored (0-5) based on:
1. Having an icon (`icon.png`).
2. Having a cover image (thumbnail).
3. Having a license defined in the manifest.
4. Having a rating of 3 or higher.
5. Using an HTML description rather than plain text (e.g., `.rst`).

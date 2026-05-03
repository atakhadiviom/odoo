const stripTrailingSlash = (value: string) => value.replace(/\/+$/, '');

export const config = {
  baseUrl: stripTrailingSlash(
    process.env.EXPO_PUBLIC_ODOO_BASE_URL || 'http://localhost:8069'
  ),
  db: process.env.EXPO_PUBLIC_ODOO_DB || 'odoo19',
  returnUrl:
    process.env.EXPO_PUBLIC_ODOO_RETURN_URL || 'synthoshop://checkout/result',
};

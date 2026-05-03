class AppConfig {
  static const String baseUrl = String.fromEnvironment(
    'ODOO_BASE_URL',
    defaultValue: 'http://localhost:8069',
  );

  static const String database = String.fromEnvironment(
    'ODOO_DATABASE',
    defaultValue: 'syntho_mobile_ecommerce_20260415',
  );

  static const String returnUrl = String.fromEnvironment(
    'ODOO_RETURN_URL',
    defaultValue: 'synthoshop://checkout/result',
  );

  static String get trimmedBaseUrl => baseUrl.replaceAll(RegExp(r'/+$'), '');
}

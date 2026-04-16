import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/mobile_models.dart';

class OdooApiException implements Exception {
  OdooApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OdooApi {
  OdooApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, String> _cookieJar = <String, String>{};

  Uri _buildUri(String path) => Uri.parse('${AppConfig.trimmedBaseUrl}$path');

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_cookieJar.isNotEmpty) {
      headers['Cookie'] = _cookieJar.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    return headers;
  }

  void _captureCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) {
      return;
    }
    for (final rawCookie in setCookie.split(',')) {
      final firstPart = rawCookie.split(';').first.trim();
      final separatorIndex = firstPart.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      final name = firstPart.substring(0, separatorIndex);
      final value = firstPart.substring(separatorIndex + 1);
      _cookieJar[name] = value;
    }
  }

  Future<Map<String, dynamic>> _callJsonRpc(
    String path, {
    Map<String, dynamic> params = const <String, dynamic>{},
  }) async {
    final response = await _client.post(
      _buildUri(path),
      headers: _headers(),
      body: jsonEncode(<String, dynamic>{
        'jsonrpc': '2.0',
        'method': 'call',
        'params': params,
        'id': DateTime.now().millisecondsSinceEpoch,
      }),
    );
    _captureCookies(response);

    final envelope = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400 || envelope['error'] != null) {
      final error = envelope['error'] as Map<String, dynamic>?;
      final data = error?['data'] as Map<String, dynamic>?;
      throw OdooApiException(
        (data?['message'] ?? error?['message'] ?? 'Request failed').toString(),
      );
    }
    return envelope['result'] as Map<String, dynamic>;
  }

  Future<void> authenticate(String login, String password) async {
    await _callJsonRpc(
      '/web/session/authenticate',
      params: <String, dynamic>{
        'db': AppConfig.database,
        'login': login,
        'password': password,
      },
    );
  }

  Future<void> logout() async {
    await _callJsonRpc('/web/session/destroy');
    _cookieJar.clear();
  }

  Future<HomePayload> getHome() async {
    final json = await _callJsonRpc('/mobile_api/home');
    return HomePayload.fromJson(json);
  }

  Future<BootstrapPayload> getBootstrap() async {
    final json = await _callJsonRpc('/mobile_api/bootstrap');
    return BootstrapPayload.fromJson(json);
  }

  Future<ProductListPayload> listProducts({
    String search = '',
    int? categoryId,
    int? brandId,
    int limit = 20,
    int offset = 0,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/products',
      params: <String, dynamic>{
        'search': search,
        'category_id': categoryId,
        'brand_id': brandId,
        'limit': limit,
        'offset': offset,
      },
    );
    return ProductListPayload.fromJson(json);
  }

  Future<BrandListPayload> getBrands({int limit = 80, int offset = 0}) async {
    final json = await _callJsonRpc(
      '/mobile_api/brands',
      params: <String, dynamic>{'limit': limit, 'offset': offset},
    );
    return BrandListPayload.fromJson(json);
  }

  Future<ProductListPayload> getProductsByBrand(
    int brandId, {
    int limit = 24,
    int offset = 0,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/products/by_brand',
      params: <String, dynamic>{
        'brand_id': brandId,
        'limit': limit,
        'offset': offset,
      },
    );
    return ProductListPayload.fromJson(json);
  }

  Future<MobileProduct> lookupBarcode(String barcode) async {
    final json = await _callJsonRpc(
      '/mobile_api/products/barcode',
      params: <String, dynamic>{'barcode': barcode},
    );
    return MobileProduct.fromJson(json);
  }

  Future<MobileProduct> getProduct(int productTemplateId) async {
    final json = await _callJsonRpc(
      '/mobile_api/product',
      params: <String, dynamic>{'product_tmpl_id': productTemplateId},
    );
    return MobileProduct.fromJson(json);
  }

  Future<CartPayload> getCart() async {
    final json = await _callJsonRpc('/mobile_api/cart');
    return CartPayload.fromJson(json);
  }

  Future<CartPayload> addToCart(int productId, {double quantity = 1}) async {
    final json = await _callJsonRpc(
      '/mobile_api/cart/add',
      params: <String, dynamic>{
        'product_id': productId,
        'quantity': quantity,
      },
    );
    return CartPayload.fromJson(json);
  }

  Future<CartPayload> updateCartLine(int lineId, double quantity) async {
    final json = await _callJsonRpc(
      '/mobile_api/cart/update',
      params: <String, dynamic>{
        'line_id': lineId,
        'quantity': quantity,
      },
    );
    return CartPayload.fromJson(json);
  }

  Future<AccountPayload> getAccount() async {
    final json = await _callJsonRpc('/mobile_api/account');
    return AccountPayload.fromJson(json);
  }

  Future<WishlistPayload> getWishlist() async {
    final json = await _callJsonRpc('/mobile_api/wishlist');
    return WishlistPayload.fromJson(json);
  }

  Future<WishlistPayload> toggleWishlist(int productId) async {
    final json = await _callJsonRpc(
      '/mobile_api/wishlist/toggle',
      params: <String, dynamic>{'product_id': productId},
    );
    return WishlistPayload.fromJson(json);
  }

  Future<MobileProduct> rateProduct({
    required int productId,
    required int rating,
    String review = '',
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/product/rate',
      params: <String, dynamic>{
        'product_id': productId,
        'rating': rating,
        'review': review,
      },
    );
    return MobileProduct.fromJson(json);
  }

  Future<CheckoutState> getCheckoutState() async {
    final json = await _callJsonRpc('/mobile_api/checkout/state');
    return CheckoutState.fromJson(json);
  }

  Future<AddressSchema> getAddressSchema({
    required String addressType,
    int? countryId,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/checkout/address_schema',
      params: <String, dynamic>{
        'address_type': addressType,
        'country_id': countryId,
      },
    );
    return AddressSchema.fromJson(json);
  }

  Future<CheckoutState> upsertCheckoutAddress({
    required CheckoutAddressInput values,
    required String addressType,
    int? partnerId,
    bool useDeliveryAsBilling = false,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/checkout/address_upsert',
      params: <String, dynamic>{
        'values': values.toJson(),
        'address_type': addressType,
        'partner_id': partnerId,
        'use_delivery_as_billing': useDeliveryAsBilling,
      },
    );
    return CheckoutState.fromJson(json);
  }

  Future<DeliveryMethodsPayload> getDeliveryMethods() async {
    final json = await _callJsonRpc('/mobile_api/checkout/delivery_methods');
    return DeliveryMethodsPayload.fromJson(json);
  }

  Future<CheckoutState> selectDeliveryMethod(int carrierId) async {
    final json = await _callJsonRpc(
      '/mobile_api/checkout/delivery_select',
      params: <String, dynamic>{'carrier_id': carrierId},
    );
    return CheckoutState.fromJson(json);
  }

  Future<PaymentOptionsPayload> getPaymentOptions() async {
    final json = await _callJsonRpc('/mobile_api/checkout/payment_options');
    return PaymentOptionsPayload.fromJson(json);
  }

  Future<PaymentSession> createPaymentSession({
    int? providerId,
    int? paymentMethodId,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/checkout/payment_session',
      params: <String, dynamic>{
        'provider_id': providerId,
        'payment_method_id': paymentMethodId,
        'return_url': AppConfig.returnUrl,
      },
    );
    return PaymentSession.fromJson(json);
  }

  Future<CheckoutResult> getPaymentStatus({
    required int orderId,
    required String accessToken,
    int? txId,
  }) async {
    final json = await _callJsonRpc(
      '/mobile_api/checkout/payment_status',
      params: <String, dynamic>{
        'order_id': orderId,
        'access_token': accessToken,
        'tx_id': txId,
      },
    );
    return CheckoutResult.fromJson(json);
  }

  void dispose() {
    _client.close();
  }
}

int? _intOrNull(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

String? _stringOrNull(dynamic value) {
  if (value is String) {
    return value;
  }
  return null;
}

String _stringOrEmpty(dynamic value) {
  return _stringOrNull(value) ?? '';
}

class WebsiteInfo {
  WebsiteInfo({
    required this.id,
    required this.name,
    required this.companyName,
    required this.companyLogoUrl,
    required this.currency,
    required this.baseUrl,
  });

  factory WebsiteInfo.fromJson(Map<String, dynamic> json) {
    return WebsiteInfo(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      companyName: (json['company_name'] ?? '') as String,
      companyLogoUrl: _stringOrNull(json['company_logo_url']),
      currency: (json['currency'] ?? 'USD') as String,
      baseUrl: (json['base_url'] ?? '') as String,
    );
  }

  final int id;
  final String name;
  final String companyName;
  final String? companyLogoUrl;
  final String currency;
  final String baseUrl;
}

enum AppTab { home, shop, brands, scan, cart, account, wishlist }

enum CheckoutStep { review, address, delivery, payment, result }

class MobileBanner {
  MobileBanner({
    required this.id,
    required this.name,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.actionKind,
    this.productTemplateId,
    this.categoryId,
    this.externalUrl,
  });

  factory MobileBanner.fromJson(Map<String, dynamic> json) {
    return MobileBanner(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      subtitle: _stringOrEmpty(json['subtitle']),
      imageUrl: (json['image_url'] ?? '') as String,
      actionKind: (json['action_kind'] ?? 'url') as String,
      productTemplateId: _intOrNull(json['product_tmpl_id']),
      categoryId: _intOrNull(json['category_id']),
      externalUrl: _stringOrNull(json['external_url']),
    );
  }

  final int id;
  final String name;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String actionKind;
  final int? productTemplateId;
  final int? categoryId;
  final String? externalUrl;
}

class MobileCategory {
  MobileCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
  });

  factory MobileCategory.fromJson(Map<String, dynamic> json) {
    return MobileCategory(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      description: _stringOrEmpty(json['description']),
      imageUrl: (json['image_url'] ?? '') as String,
    );
  }

  final int id;
  final String name;
  final String description;
  final String imageUrl;
}

class MobileProduct {
  MobileProduct({
    required this.id,
    required this.variantId,
    required this.name,
    required this.price,
    required this.listPrice,
    required this.currency,
    required this.description,
    required this.shortDescription,
    required this.imageUrl,
    required this.extraImageUrls,
    required this.websiteUrl,
    required this.categoryIds,
    required this.categoryNames,
    required this.avgRating,
    required this.ratingCount,
    required this.ratings,
    this.defaultCode,
    this.brandId,
    this.brandName,
  });

  factory MobileProduct.fromJson(Map<String, dynamic> json) {
    return MobileProduct(
      id: json['id'] as int,
      variantId: json['variant_id'] as int,
      name: (json['name'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      description: (json['description'] ?? '') as String,
      shortDescription: (json['short_description'] ?? '') as String,
      imageUrl: (json['image_url'] ?? '') as String,
      extraImageUrls:
          (json['extra_image_urls'] as List<dynamic>? ?? <dynamic>[])
              .map((item) => item as String)
              .toList(),
      websiteUrl: (json['website_url'] ?? '') as String,
      categoryIds: (json['category_ids'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item as int)
          .toList(),
      categoryNames: (json['category_names'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
      ratingCount: _intOrNull(json['rating_count']) ?? 0,
      ratings: (json['ratings'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => ProductRating.fromJson(item as Map<String, dynamic>))
          .toList(),
      defaultCode: _stringOrNull(json['default_code']),
      brandId: _intOrNull(json['brand_id']),
      brandName: _stringOrNull(json['brand_name']),
    );
  }

  final int id;
  final int variantId;
  final String name;
  final double price;
  final double listPrice;
  final String currency;
  final String description;
  final String shortDescription;
  final String imageUrl;
  final List<String> extraImageUrls;
  final String websiteUrl;
  final List<int> categoryIds;
  final List<String> categoryNames;
  final double avgRating;
  final int ratingCount;
  final List<ProductRating> ratings;
  final String? defaultCode;
  final int? brandId;
  final String? brandName;
}

class ProductBrand {
  ProductBrand({
    required this.id,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.productCount,
  });

  factory ProductBrand.fromJson(Map<String, dynamic> json) {
    return ProductBrand(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      description: _stringOrEmpty(json['description']),
      logoUrl: _stringOrEmpty(json['logo_url']),
      productCount: _intOrNull(json['product_count']) ?? 0,
    );
  }

  final int id;
  final String name;
  final String description;
  final String logoUrl;
  final int productCount;
}

class BrandListPayload {
  BrandListPayload({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory BrandListPayload.fromJson(Map<String, dynamic> json) {
    return BrandListPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => ProductBrand.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: _intOrNull(json['total']) ?? 0,
      limit: _intOrNull(json['limit']) ?? 80,
      offset: _intOrNull(json['offset']) ?? 0,
    );
  }

  final List<ProductBrand> items;
  final int total;
  final int limit;
  final int offset;
}

class ProductRating {
  ProductRating({
    required this.id,
    required this.productTemplateId,
    required this.partnerName,
    required this.rating,
    required this.review,
    this.date,
  });

  factory ProductRating.fromJson(Map<String, dynamic> json) {
    return ProductRating(
      id: json['id'] as int,
      productTemplateId: json['product_tmpl_id'] as int,
      partnerName: (json['partner_name'] ?? '') as String,
      rating: _intOrNull(json['rating']) ?? 0,
      review: _stringOrEmpty(json['review']),
      date: _stringOrNull(json['date']),
    );
  }

  final int id;
  final int productTemplateId;
  final String partnerName;
  final int rating;
  final String review;
  final String? date;
}

class HomePayload {
  HomePayload({
    required this.website,
    required this.banners,
    required this.categories,
    required this.featuredProducts,
  });

  factory HomePayload.fromJson(Map<String, dynamic> json) {
    return HomePayload(
      website: WebsiteInfo.fromJson(json['website'] as Map<String, dynamic>),
      banners: (json['banners'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => MobileBanner.fromJson(item as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => MobileCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
      featuredProducts: (json['featured_products'] as List<dynamic>? ??
              <dynamic>[])
          .map((item) => MobileProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final WebsiteInfo website;
  final List<MobileBanner> banners;
  final List<MobileCategory> categories;
  final List<MobileProduct> featuredProducts;
}

class ManagedMobileApp {
  ManagedMobileApp({
    required this.id,
    required this.name,
    required this.appCode,
    required this.bundleIdentifier,
    required this.packageName,
    required this.appScheme,
    required this.returnUrl,
    required this.logoUrl,
    required this.configuredLogoUrl,
    required this.splashImageUrl,
    required this.primaryColor,
    required this.accentColor,
    required this.minimumSupportedVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.maintenanceMode,
    required this.maintenanceMessage,
    required this.allowGuestCheckout,
    required this.wishlistEnabled,
    required this.searchEnabled,
    required this.googleLoginEnabled,
    required this.googleClientId,
    required this.googleClientIdIos,
    required this.googleClientIdAndroid,
    required this.versionNotes,
  });

  factory ManagedMobileApp.fromJson(Map<String, dynamic> json) {
    return ManagedMobileApp(
      id: _intOrNull(json['id']),
      name: (json['name'] ?? '') as String,
      appCode: (json['app_code'] ?? 'main') as String,
      bundleIdentifier: _stringOrNull(json['bundle_identifier']),
      packageName: _stringOrNull(json['package_name']),
      appScheme: (json['app_scheme'] ?? 'synthoshop') as String,
      returnUrl:
          (json['return_url'] ?? 'synthoshop://checkout/result') as String,
      logoUrl: _stringOrNull(json['logo_url']),
      configuredLogoUrl: _stringOrNull(json['configured_logo_url']),
      splashImageUrl: _stringOrNull(json['splash_image_url']),
      primaryColor: (json['primary_color'] ?? '#C06E52') as String,
      accentColor: (json['accent_color'] ?? '#142633') as String,
      minimumSupportedVersion: _stringOrNull(json['minimum_supported_version']),
      latestVersion: _stringOrNull(json['latest_version']),
      forceUpdate: json['force_update'] as bool? ?? false,
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      maintenanceMessage: _stringOrNull(json['maintenance_message']),
      allowGuestCheckout: json['allow_guest_checkout'] as bool? ?? true,
      wishlistEnabled: json['wishlist_enabled'] as bool? ?? true,
      searchEnabled: json['search_enabled'] as bool? ?? true,
      googleLoginEnabled: json['google_login_enabled'] as bool? ?? false,
      googleClientId: _stringOrNull(json['google_client_id']),
      googleClientIdIos: _stringOrNull(json['google_client_id_ios']),
      googleClientIdAndroid: _stringOrNull(json['google_client_id_android']),
      versionNotes: _stringOrNull(json['version_notes']),
    );
  }

  final int? id;
  final String name;
  final String appCode;
  final String? bundleIdentifier;
  final String? packageName;
  final String appScheme;
  final String returnUrl;
  final String? logoUrl;
  final String? configuredLogoUrl;
  final String? splashImageUrl;
  final String primaryColor;
  final String accentColor;
  final String? minimumSupportedVersion;
  final String? latestVersion;
  final bool forceUpdate;
  final bool maintenanceMode;
  final String? maintenanceMessage;
  final bool allowGuestCheckout;
  final bool wishlistEnabled;
  final bool searchEnabled;
  final bool googleLoginEnabled;
  final String? googleClientId;
  final String? googleClientIdIos;
  final String? googleClientIdAndroid;
  final String? versionNotes;
}

class ManagedNavigationItem {
  ManagedNavigationItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.targetKind,
    required this.tabKey,
    required this.categoryId,
    required this.contentPageId,
    required this.externalUrl,
  });

  factory ManagedNavigationItem.fromJson(Map<String, dynamic> json) {
    return ManagedNavigationItem(
      id: json['id'] as int,
      label: (json['label'] ?? '') as String,
      icon: (json['icon'] ?? '') as String,
      targetKind: (json['target_kind'] ?? 'tab') as String,
      tabKey: _stringOrNull(json['tab_key']),
      categoryId: _intOrNull(json['category_id']),
      contentPageId: _intOrNull(json['content_page_id']),
      externalUrl: _stringOrNull(json['external_url']),
    );
  }

  final int id;
  final String label;
  final String icon;
  final String targetKind;
  final String? tabKey;
  final int? categoryId;
  final int? contentPageId;
  final String? externalUrl;
}

class ManagedContentPage {
  ManagedContentPage({
    required this.id,
    required this.name,
    required this.pageKey,
    required this.slug,
    required this.title,
    required this.summary,
    required this.coverImageUrl,
    required this.bodyHtml,
  });

  factory ManagedContentPage.fromJson(Map<String, dynamic> json) {
    return ManagedContentPage(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      pageKey: (json['page_key'] ?? 'custom') as String,
      slug: (json['slug'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      summary: (json['summary'] ?? '') as String,
      coverImageUrl: _stringOrNull(json['cover_image_url']),
      bodyHtml: (json['body_html'] ?? '') as String,
    );
  }

  final int id;
  final String name;
  final String pageKey;
  final String slug;
  final String title;
  final String summary;
  final String? coverImageUrl;
  final String bodyHtml;
}

class ManagedHomeSection {
  ManagedHomeSection({
    required this.id,
    required this.name,
    required this.sectionKey,
    required this.title,
    required this.subtitle,
    required this.sectionKind,
    required this.maxItems,
    required this.items,
  });

  factory ManagedHomeSection.fromJson(Map<String, dynamic> json) {
    return ManagedHomeSection(
      id: json['id'],
      name: (json['name'] ?? '') as String,
      sectionKey: _stringOrNull(json['section_key']),
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      sectionKind: (json['section_kind'] ?? 'featured_products') as String,
      maxItems: _intOrNull(json['max_items']) ?? 8,
      items: (json['items'] as List<dynamic>? ?? <dynamic>[]),
    );
  }

  final dynamic id;
  final String name;
  final String? sectionKey;
  final String title;
  final String subtitle;
  final String sectionKind;
  final int maxItems;
  final List<dynamic> items;

  List<MobileBanner> get banners => items
      .map((item) => MobileBanner.fromJson(item as Map<String, dynamic>))
      .toList();

  List<MobileCategory> get categories => items
      .map((item) => MobileCategory.fromJson(item as Map<String, dynamic>))
      .toList();

  List<MobileProduct> get products => items
      .map((item) => MobileProduct.fromJson(item as Map<String, dynamic>))
      .toList();

  List<ManagedContentPage> get contentPages => items
      .map((item) => ManagedContentPage.fromJson(item as Map<String, dynamic>))
      .toList();
}

class BootstrapPayload {
  BootstrapPayload({
    required this.website,
    required this.app,
    required this.navigation,
    required this.homeSections,
    required this.contentPages,
  });

  factory BootstrapPayload.fromJson(Map<String, dynamic> json) {
    return BootstrapPayload(
      website: WebsiteInfo.fromJson(json['website'] as Map<String, dynamic>),
      app: ManagedMobileApp.fromJson(json['app'] as Map<String, dynamic>),
      navigation: (json['navigation'] as List<dynamic>? ?? <dynamic>[])
          .map((item) =>
              ManagedNavigationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      homeSections: (json['home_sections'] as List<dynamic>? ?? <dynamic>[])
          .map((item) =>
              ManagedHomeSection.fromJson(item as Map<String, dynamic>))
          .toList(),
      contentPages: (json['content_pages'] as List<dynamic>? ?? <dynamic>[])
          .map((item) =>
              ManagedContentPage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final WebsiteInfo website;
  final ManagedMobileApp app;
  final List<ManagedNavigationItem> navigation;
  final List<ManagedHomeSection> homeSections;
  final List<ManagedContentPage> contentPages;
}

class ProductListPayload {
  ProductListPayload({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  factory ProductListPayload.fromJson(Map<String, dynamic> json) {
    return ProductListPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => MobileProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: _intOrNull(json['total']) ?? 0,
      limit: _intOrNull(json['limit']) ?? 20,
      offset: _intOrNull(json['offset']) ?? 0,
    );
  }

  final List<MobileProduct> items;
  final int total;
  final int limit;
  final int offset;
}

class WishlistPayload {
  WishlistPayload({
    required this.items,
    required this.productIds,
    required this.total,
    this.toggledProductId,
    this.wished,
  });

  factory WishlistPayload.fromJson(Map<String, dynamic> json) {
    return WishlistPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => MobileProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      productIds: (json['product_ids'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => _intOrNull(item))
          .whereType<int>()
          .toSet(),
      total: _intOrNull(json['total']) ?? 0,
      toggledProductId: _intOrNull(json['product_id']),
      wished: json['wished'] as bool?,
    );
  }

  final List<MobileProduct> items;
  final Set<int> productIds;
  final int total;
  final int? toggledProductId;
  final bool? wished;
}

class CartLine {
  CartLine({
    required this.id,
    required this.productTemplateId,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.priceUnit,
    required this.subtotal,
    required this.total,
    required this.currency,
    required this.imageUrl,
    required this.isDelivery,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      id: json['id'] as int,
      productTemplateId: json['product_tmpl_id'] as int,
      productId: json['product_id'] as int,
      name: (json['name'] ?? '') as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      priceUnit: (json['price_unit'] as num?)?.toDouble() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      imageUrl: (json['image_url'] ?? '') as String,
      isDelivery: json['is_delivery'] as bool? ?? false,
    );
  }

  final int id;
  final int productTemplateId;
  final int productId;
  final String name;
  final double quantity;
  final double priceUnit;
  final double subtotal;
  final double total;
  final String currency;
  final String imageUrl;
  final bool isDelivery;
}

class CartPayload {
  CartPayload({
    required this.orderId,
    required this.cartQuantity,
    required this.amountUntaxed,
    required this.amountTax,
    required this.amountTotal,
    required this.currency,
    required this.checkoutUrl,
    required this.requiresDelivery,
    required this.canCheckout,
    required this.lines,
  });

  factory CartPayload.empty() {
    return CartPayload(
      orderId: null,
      cartQuantity: 0,
      amountUntaxed: 0,
      amountTax: 0,
      amountTotal: 0,
      currency: 'USD',
      checkoutUrl: '',
      requiresDelivery: false,
      canCheckout: false,
      lines: <CartLine>[],
    );
  }

  factory CartPayload.fromJson(Map<String, dynamic> json) {
    return CartPayload(
      orderId: _intOrNull(json['order_id']),
      cartQuantity: (json['cart_quantity'] as num?)?.toDouble() ?? 0,
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      checkoutUrl: (json['checkout_url'] ?? '') as String,
      requiresDelivery: json['requires_delivery'] as bool? ?? false,
      canCheckout: json['can_checkout'] as bool? ?? false,
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CartLine.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int? orderId;
  final double cartQuantity;
  final double amountUntaxed;
  final double amountTax;
  final double amountTotal;
  final String currency;
  final String checkoutUrl;
  final bool requiresDelivery;
  final bool canCheckout;
  final List<CartLine> lines;
}

class PartnerSummary {
  PartnerSummary({
    required this.id,
    required this.name,
    this.email,
    this.phone,
  });

  factory PartnerSummary.fromJson(Map<String, dynamic> json) {
    return PartnerSummary(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      email: _stringOrNull(json['email']),
      phone: _stringOrNull(json['phone']),
    );
  }

  final int id;
  final String name;
  final String? email;
  final String? phone;
}

class OrderSummary {
  OrderSummary({
    required this.id,
    required this.name,
    required this.state,
    required this.amountTotal,
    required this.amountTax,
    required this.amountUntaxed,
    required this.currency,
    required this.lines,
    required this.needsPayment,
    this.dateOrder,
    this.portalUrl,
    this.accessToken,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      state: (json['state'] ?? '') as String,
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      amountTax: (json['amount_tax'] as num?)?.toDouble() ?? 0,
      amountUntaxed: (json['amount_untaxed'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      lines: (json['lines'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CartLine.fromJson(item as Map<String, dynamic>))
          .toList(),
      needsPayment: json['needs_payment'] as bool? ?? false,
      dateOrder: _stringOrNull(json['date_order']),
      portalUrl: _stringOrNull(json['portal_url']),
      accessToken: _stringOrNull(json['access_token']),
    );
  }

  final int id;
  final String name;
  final String state;
  final double amountTotal;
  final double amountTax;
  final double amountUntaxed;
  final String currency;
  final List<CartLine> lines;
  final bool needsPayment;
  final String? dateOrder;
  final String? portalUrl;
  final String? accessToken;
}

class AccountPayload {
  AccountPayload({
    required this.partner,
    required this.orders,
    required this.ordersCount,
  });

  factory AccountPayload.fromJson(Map<String, dynamic> json) {
    return AccountPayload(
      partner: PartnerSummary.fromJson(json['partner'] as Map<String, dynamic>),
      orders: (json['orders'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => OrderSummary.fromJson(item as Map<String, dynamic>))
          .toList(),
      ordersCount: _intOrNull(json['orders_count']) ?? 0,
    );
  }

  final PartnerSummary partner;
  final List<OrderSummary> orders;
  final int ordersCount;
}

class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.isRead,
    required this.pushSent,
    this.createdAt,
    this.readAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _intOrNull(json['id']) ?? 0,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      type: (json['type'] ?? 'info') as String,
      data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      isRead: json['is_read'] as bool? ?? false,
      pushSent: json['push_sent'] as bool? ?? false,
      createdAt: _stringOrNull(json['created_at']),
      readAt: _stringOrNull(json['read_at']),
    );
  }

  final int id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  final bool isRead;
  final bool pushSent;
  final String? createdAt;
  final String? readAt;
}

class NotificationPayload {
  NotificationPayload({
    required this.items,
    required this.unreadCount,
  });

  factory NotificationPayload.empty() {
    return NotificationPayload(items: <AppNotification>[], unreadCount: 0);
  }

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    return NotificationPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
          .toList(),
      unreadCount: _intOrNull(json['unread_count']) ?? 0,
    );
  }

  final List<AppNotification> items;
  final int unreadCount;
}

class CheckoutError {
  CheckoutError({
    required this.title,
    this.message,
    this.code,
  });

  factory CheckoutError.fromJson(Map<String, dynamic> json) {
    return CheckoutError(
      title: (json['title'] ?? '') as String,
      message: _stringOrNull(json['message']),
      code: _stringOrNull(json['code']),
    );
  }

  final String title;
  final String? message;
  final String? code;
}

class CountryOption {
  CountryOption({required this.id, required this.name, required this.code});

  factory CountryOption.fromJson(Map<String, dynamic> json) {
    return CountryOption(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      code: (json['code'] ?? '') as String,
    );
  }

  final int id;
  final String name;
  final String code;
}

class StateOption {
  StateOption({required this.id, required this.name, this.code});

  factory StateOption.fromJson(Map<String, dynamic> json) {
    return StateOption(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      code: _stringOrNull(json['code']),
    );
  }

  final int id;
  final String name;
  final String? code;
}

class PartnerAddress {
  PartnerAddress({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.street,
    this.street2,
    this.city,
    this.zip,
    this.countryId,
    this.countryName,
    this.stateId,
    this.stateName,
    this.companyName,
    this.vat,
  });

  factory PartnerAddress.fromJson(Map<String, dynamic> json) {
    return PartnerAddress(
      id: json['id'] as int,
      name: _stringOrNull(json['name']),
      email: _stringOrNull(json['email']),
      phone: _stringOrNull(json['phone']),
      street: _stringOrNull(json['street']),
      street2: _stringOrNull(json['street2']),
      city: _stringOrNull(json['city']),
      zip: _stringOrNull(json['zip']),
      countryId: _intOrNull(json['country_id']),
      countryName: _stringOrNull(json['country_name']),
      stateId: _intOrNull(json['state_id']),
      stateName: _stringOrNull(json['state_name']),
      companyName: _stringOrNull(json['company_name']),
      vat: _stringOrNull(json['vat']),
    );
  }

  final int id;
  final String? name;
  final String? email;
  final String? phone;
  final String? street;
  final String? street2;
  final String? city;
  final String? zip;
  final int? countryId;
  final String? countryName;
  final int? stateId;
  final String? stateName;
  final String? companyName;
  final String? vat;
}

class CheckoutAddressInput {
  CheckoutAddressInput({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.street = '',
    this.street2 = '',
    this.city = '',
    this.zip = '',
    this.countryId,
    this.stateId,
    this.companyName = '',
    this.vat = '',
  });

  factory CheckoutAddressInput.fromPartner(PartnerAddress? address) {
    return CheckoutAddressInput(
      name: address?.name ?? '',
      email: address?.email ?? '',
      phone: address?.phone ?? '',
      street: address?.street ?? '',
      street2: address?.street2 ?? '',
      city: address?.city ?? '',
      zip: address?.zip ?? '',
      countryId: address?.countryId,
      stateId: address?.stateId,
      companyName: address?.companyName ?? '',
      vat: address?.vat ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'phone': phone,
      'street': street,
      'street2': street2,
      'city': city,
      'zip': zip,
      'country_id': countryId,
      'state_id': stateId,
      'company_name': companyName,
      'vat': vat,
    };
  }

  CheckoutAddressInput copyWith({
    String? name,
    String? email,
    String? phone,
    String? street,
    String? street2,
    String? city,
    String? zip,
    int? countryId,
    int? stateId,
    String? companyName,
    String? vat,
  }) {
    return CheckoutAddressInput(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      zip: zip ?? this.zip,
      countryId: countryId ?? this.countryId,
      stateId: stateId ?? this.stateId,
      companyName: companyName ?? this.companyName,
      vat: vat ?? this.vat,
    );
  }

  final String name;
  final String email;
  final String phone;
  final String street;
  final String street2;
  final String city;
  final String zip;
  final int? countryId;
  final int? stateId;
  final String companyName;
  final String vat;
}

class AddressSchema {
  AddressSchema({
    required this.addressType,
    required this.selectedCountryId,
    required this.addressFields,
    required this.requiredFields,
    required this.zipBeforeCity,
    required this.phoneCode,
    required this.countries,
    required this.states,
  });

  factory AddressSchema.fromJson(Map<String, dynamic> json) {
    return AddressSchema(
      addressType: (json['address_type'] ?? 'billing') as String,
      selectedCountryId: _intOrNull(json['selected_country_id']),
      addressFields: (json['address_fields'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      requiredFields: (json['required_fields'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      zipBeforeCity: json['zip_before_city'] as bool? ?? false,
      phoneCode: _intOrNull(json['phone_code']),
      countries: (json['countries'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CountryOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      states: (json['states'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => StateOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String addressType;
  final int? selectedCountryId;
  final List<String> addressFields;
  final List<String> requiredFields;
  final bool zipBeforeCity;
  final int? phoneCode;
  final List<CountryOption> countries;
  final List<StateOption> states;
}

class DeliveryMethod {
  DeliveryMethod({
    required this.id,
    required this.name,
    required this.amount,
    required this.currency,
    required this.selected,
    required this.countries,
    required this.countryNames,
    required this.restrictedToCountries,
    this.shippingCountryId,
    this.shippingCountryName,
  });

  factory DeliveryMethod.fromJson(Map<String, dynamic> json) {
    return DeliveryMethod(
      id: json['id'] as int,
      name: (json['name'] ?? '') as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      selected: json['selected'] as bool? ?? false,
      countries: (json['countries'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CountryOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      countryNames: (json['country_names'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      restrictedToCountries: json['restricted_to_countries'] as bool? ?? false,
      shippingCountryId: _intOrNull(json['shipping_country_id']),
      shippingCountryName: _stringOrNull(json['shipping_country_name']),
    );
  }

  final int id;
  final String name;
  final double amount;
  final String currency;
  final bool selected;
  final List<CountryOption> countries;
  final List<String> countryNames;
  final bool restrictedToCountries;
  final int? shippingCountryId;
  final String? shippingCountryName;

  String get countrySummary {
    if (!restrictedToCountries || countryNames.isEmpty) {
      return 'Available for all configured shipping countries';
    }
    if (countryNames.length <= 3) {
      return 'Ships to ${countryNames.join(', ')}';
    }
    return 'Ships to ${countryNames.take(3).join(', ')} +${countryNames.length - 3} more';
  }
}

class DeliveryMethodsPayload {
  DeliveryMethodsPayload({
    required this.items,
    this.selectedDeliveryMethod,
    this.orderId,
    required this.amountTotal,
    required this.currency,
    this.shippingCountry,
  });

  factory DeliveryMethodsPayload.fromJson(Map<String, dynamic> json) {
    return DeliveryMethodsPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => DeliveryMethod.fromJson(item as Map<String, dynamic>))
          .toList(),
      selectedDeliveryMethod: json['selected_delivery_method'] == null ||
              json['selected_delivery_method'] == false
          ? null
          : DeliveryMethod.fromJson(
              json['selected_delivery_method'] as Map<String, dynamic>,
            ),
      orderId: _intOrNull(json['order_id']),
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      shippingCountry:
          json['shipping_country'] == null || json['shipping_country'] == false
              ? null
              : CountryOption.fromJson(
                  json['shipping_country'] as Map<String, dynamic>,
                ),
    );
  }

  final List<DeliveryMethod> items;
  final DeliveryMethod? selectedDeliveryMethod;
  final int? orderId;
  final double amountTotal;
  final String currency;
  final CountryOption? shippingCountry;
}

class PaymentOption {
  PaymentOption({
    required this.providerId,
    required this.providerCode,
    required this.providerName,
    required this.paymentMethodId,
    required this.paymentMethodCode,
    required this.paymentMethodName,
    required this.flow,
    required this.countries,
    required this.countryNames,
    required this.restrictedToCountries,
  });

  factory PaymentOption.fromJson(Map<String, dynamic> json) {
    return PaymentOption(
      providerId: json['provider_id'] as int,
      providerCode: (json['provider_code'] ?? '') as String,
      providerName: (json['provider_name'] ?? '') as String,
      paymentMethodId: json['payment_method_id'] as int,
      paymentMethodCode: (json['payment_method_code'] ?? '') as String,
      paymentMethodName: (json['payment_method_name'] ?? '') as String,
      flow: (json['flow'] ?? 'redirect') as String,
      countries: (json['countries'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CountryOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      countryNames: (json['country_names'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      restrictedToCountries: json['restricted_to_countries'] as bool? ?? false,
    );
  }

  final int providerId;
  final String providerCode;
  final String providerName;
  final int paymentMethodId;
  final String paymentMethodCode;
  final String paymentMethodName;
  final String flow;
  final List<CountryOption> countries;
  final List<String> countryNames;
  final bool restrictedToCountries;

  String get selectionKey => '$providerId:$paymentMethodId';

  String get countrySummary {
    if (!restrictedToCountries || countryNames.isEmpty) {
      return 'Available for all billing countries';
    }
    if (countryNames.length <= 3) {
      return 'Available in ${countryNames.join(', ')}';
    }
    return 'Available in ${countryNames.take(3).join(', ')} +${countryNames.length - 3} more';
  }
}

class PaymentOptionsPayload {
  PaymentOptionsPayload({
    required this.items,
    required this.errors,
    this.orderId,
    required this.amountTotal,
    required this.currency,
    this.billingCountry,
  });

  factory PaymentOptionsPayload.fromJson(Map<String, dynamic> json) {
    return PaymentOptionsPayload(
      items: (json['items'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => PaymentOption.fromJson(item as Map<String, dynamic>))
          .toList(),
      errors: (json['errors'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CheckoutError.fromJson(item as Map<String, dynamic>))
          .toList(),
      orderId: _intOrNull(json['order_id']),
      amountTotal: (json['amount_total'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] ?? 'USD') as String,
      billingCountry:
          json['billing_country'] == null || json['billing_country'] == false
              ? null
              : CountryOption.fromJson(
                  json['billing_country'] as Map<String, dynamic>,
                ),
    );
  }

  final List<PaymentOption> items;
  final List<CheckoutError> errors;
  final int? orderId;
  final double amountTotal;
  final String currency;
  final CountryOption? billingCountry;
}

class CheckoutState {
  CheckoutState({
    this.orderId,
    this.orderName,
    this.accessToken,
    required this.loginRequired,
    required this.isAuthenticated,
    required this.requiresDelivery,
    required this.paymentRequired,
    required this.billingComplete,
    required this.shippingComplete,
    required this.billingAddress,
    required this.shippingAddress,
    required this.selectedDeliveryMethod,
    required this.canProceedToPayment,
    required this.canFinalizeWithoutPayment,
    required this.checkoutErrors,
    required this.cart,
    this.success,
    this.partnerId,
    this.invalidFields = const <String>[],
    this.messages = const <String>[],
  });

  factory CheckoutState.fromJson(Map<String, dynamic> json) {
    return CheckoutState(
      orderId: _intOrNull(json['order_id']),
      orderName: _stringOrNull(json['order_name']),
      accessToken: _stringOrNull(json['access_token']),
      loginRequired: json['login_required'] as bool? ?? false,
      isAuthenticated: json['is_authenticated'] as bool? ?? false,
      requiresDelivery: json['requires_delivery'] as bool? ?? false,
      paymentRequired: json['payment_required'] as bool? ?? false,
      billingComplete: json['billing_complete'] as bool? ?? false,
      shippingComplete: json['shipping_complete'] as bool? ?? false,
      billingAddress:
          json['billing_address'] == null || json['billing_address'] == false
              ? null
              : PartnerAddress.fromJson(
                  json['billing_address'] as Map<String, dynamic>),
      shippingAddress:
          json['shipping_address'] == null || json['shipping_address'] == false
              ? null
              : PartnerAddress.fromJson(
                  json['shipping_address'] as Map<String, dynamic>),
      selectedDeliveryMethod: json['selected_delivery_method'] == null ||
              json['selected_delivery_method'] == false
          ? null
          : DeliveryMethod.fromJson(
              json['selected_delivery_method'] as Map<String, dynamic>,
            ),
      canProceedToPayment: json['can_proceed_to_payment'] as bool? ?? false,
      canFinalizeWithoutPayment:
          json['can_finalize_without_payment'] as bool? ?? false,
      checkoutErrors: (json['checkout_errors'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => CheckoutError.fromJson(item as Map<String, dynamic>))
          .toList(),
      cart: CartPayload.fromJson(json['cart'] as Map<String, dynamic>),
      success: json['success'] as bool?,
      partnerId: _intOrNull(json['partner_id']),
      invalidFields: (json['invalid_fields'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      messages: (json['messages'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
    );
  }

  final int? orderId;
  final String? orderName;
  final String? accessToken;
  final bool loginRequired;
  final bool isAuthenticated;
  final bool requiresDelivery;
  final bool paymentRequired;
  final bool billingComplete;
  final bool shippingComplete;
  final PartnerAddress? billingAddress;
  final PartnerAddress? shippingAddress;
  final DeliveryMethod? selectedDeliveryMethod;
  final bool canProceedToPayment;
  final bool canFinalizeWithoutPayment;
  final List<CheckoutError> checkoutErrors;
  final CartPayload cart;
  final bool? success;
  final int? partnerId;
  final List<String> invalidFields;
  final List<String> messages;
}

class PaymentSession {
  PaymentSession({
    required this.txId,
    required this.orderId,
    required this.paymentPageUrl,
    required this.returnUrl,
    required this.accessToken,
    required this.status,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> json) {
    return PaymentSession(
      txId: _intOrNull(json['tx_id']),
      orderId: json['order_id'] as int,
      paymentPageUrl: _stringOrNull(json['payment_page_url']),
      returnUrl: (json['return_url'] ?? '') as String,
      accessToken: (json['access_token'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
    );
  }

  final int? txId;
  final int orderId;
  final String? paymentPageUrl;
  final String returnUrl;
  final String accessToken;
  final String status;
}

class CheckoutResult {
  CheckoutResult({
    this.orderId,
    this.orderName,
    this.orderState,
    this.txId,
    this.txState,
    required this.status,
    this.accessToken,
    this.message,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: _intOrNull(json['order_id']),
      orderName: _stringOrNull(json['order_name']),
      orderState: _stringOrNull(json['order_state']),
      txId: _intOrNull(json['tx_id']),
      txState: _stringOrNull(json['tx_state']),
      status: (json['status'] ?? 'pending') as String,
      accessToken: _stringOrNull(json['access_token']),
      message: _stringOrNull(json['message']),
    );
  }

  final int? orderId;
  final String? orderName;
  final String? orderState;
  final int? txId;
  final String? txState;
  final String status;
  final String? accessToken;
  final String? message;
}

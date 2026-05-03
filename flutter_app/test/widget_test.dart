import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syntho_shop_flutter/src/models/mobile_models.dart';
import 'package:syntho_shop_flutter/src/screens/app_shell.dart';
import 'package:syntho_shop_flutter/src/screens/home_screen.dart';
import 'package:syntho_shop_flutter/src/widgets/app_vector_icons.dart';
import 'package:syntho_shop_flutter/src/widgets/checkout_widgets.dart';
import 'package:syntho_shop_flutter/src/widgets/common.dart';

void main() {
  testWidgets('test harness is configured', (WidgetTester tester) async {
    expect(true, isTrue);
  });

  test('bottom navigation hides brands and scan tabs from managed navigation',
      () {
    final items = <ManagedNavigationItem>[
      _navItem(id: 1, label: 'Home', icon: 'home', tabKey: 'home'),
      _navItem(id: 2, label: 'Shop', icon: 'shopping_bag', tabKey: 'shop'),
      _navItem(id: 3, label: 'Cart', icon: 'shopping_cart', tabKey: 'cart'),
      _navItem(id: 4, label: 'Account', icon: 'person', tabKey: 'account'),
      _navItem(id: 5, label: 'Brands', icon: 'brands', tabKey: 'brands'),
      _navItem(id: 6, label: 'Scan', icon: 'scan', tabKey: 'scan'),
      _navItem(
        id: 7,
        label: 'Promo',
        icon: 'tag',
        tabKey: null,
        targetKind: 'url',
      ),
    ];

    final visibleItems = visibleBottomNavigationItems(items);

    expect(
      visibleItems.map((item) => item.label),
      equals(<String>['Home', 'Shop', 'Cart', 'Account']),
    );
    expect(
      visibleItems.map((item) => item.tabKey),
      isNot(contains(anyOf('brands', 'scan'))),
    );
  });

  test('website bootstrap preserves the Odoo company display name', () {
    final website = WebsiteInfo.fromJson(<String, dynamic>{
      'id': 1,
      'name': 'My Website',
      'company_name': 'SynthoERP LLC',
      'company_logo_url': 'http://127.0.0.1:8123/web/image/res.company/1/logo',
      'currency': 'USD',
      'base_url': 'http://127.0.0.1:8123',
    });

    expect(website.companyName, 'SynthoERP LLC');
    expect(
      website.companyLogoUrl,
      'http://127.0.0.1:8123/web/image/res.company/1/logo',
    );
    expect(website.name, 'My Website');
  });

  test('checkout options preserve Odoo countries and quotation payment', () {
    final delivery = DeliveryMethod.fromJson(<String, dynamic>{
      'id': 10,
      'name': 'Local Delivery',
      'amount': 12.5,
      'currency': 'USD',
      'selected': false,
      'countries': <Map<String, dynamic>>[
        <String, dynamic>{'id': 233, 'name': 'United States', 'code': 'US'},
      ],
      'country_names': <String>['United States'],
      'restricted_to_countries': true,
      'shipping_country_id': 233,
      'shipping_country_name': 'United States',
    });
    final payment = PaymentOption.fromJson(<String, dynamic>{
      'provider_id': 0,
      'provider_code': 'odoo_quotation',
      'provider_name': 'Odoo quotation',
      'payment_method_id': 0,
      'payment_method_code': 'odoo_quotation',
      'payment_method_name': 'Pay on Odoo quotation',
      'flow': 'in_app_browser',
      'countries': <Map<String, dynamic>>[
        <String, dynamic>{'id': 233, 'name': 'United States', 'code': 'US'},
      ],
      'country_names': <String>['United States'],
      'restricted_to_countries': true,
    });

    expect(delivery.countrySummary, contains('United States'));
    expect(delivery.shippingCountryName, 'United States');
    expect(payment.flow, 'in_app_browser');
    expect(payment.paymentMethodName, 'Pay on Odoo quotation');
    expect(payment.selectionKey, '0:0');
    expect(payment.countrySummary, contains('United States'));
  });

  test('wishlist toggle payload parses top-level product state', () {
    final payload = WishlistPayload.fromJson(<String, dynamic>{
      'items': <Map<String, dynamic>>[],
      'product_ids': <int>[126],
      'total': 1,
      'product_id': 126,
      'wished': true,
    });

    expect(payload.productIds, contains(126));
    expect(payload.toggledProductId, 126);
    expect(payload.wished, isTrue);
  });

  test('notification payload parses unread inbox state', () {
    final payload = NotificationPayload.fromJson(<String, dynamic>{
      'unread_count': 1,
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'id': 44,
          'title': 'Order Confirmed',
          'body': 'Your order S00001 has been confirmed.',
          'type': 'order',
          'data': <String, dynamic>{'order_id': '1', 'action': 'open_order'},
          'is_read': false,
          'push_sent': true,
          'created_at': '2026-04-21T10:00:00',
        },
      ],
    });

    expect(payload.unreadCount, 1);
    expect(payload.items.single.title, 'Order Confirmed');
    expect(payload.items.single.type, 'order');
    expect(payload.items.single.data['action'], 'open_order');
    expect(payload.items.single.isRead, isFalse);
  });

  testWidgets('checkout step header shows in-flow back action',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CheckoutStepHeader(
            step: CheckoutStep.payment,
            backLabel: 'Back to delivery',
            onBack: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Back to delivery'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);

    await tester.tap(find.text('Back to delivery'));
    expect(tapped, isTrue);
  });

  testWidgets('odoo navigation aliases render as custom vector icons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Row(
            children: <Widget>[
              AppVectorIcon('home'),
              AppVectorIcon('shopping_bag'),
              AppVectorIcon('shopping_cart'),
              AppVectorIcon('back'),
              AppVectorIcon('review'),
              AppVectorIcon('share'),
              AppVectorIcon('bell'),
              AppVectorIcon('check'),
              AppStarIcon(),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(AppVectorIcon), findsNWidgets(8));
    expect(find.byType(AppStarIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(4));
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('hero banner renders as a swipeable slider',
      (WidgetTester tester) async {
    var selectedProductId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HeroCard(
            payload: null,
            bootstrap: null,
            banners: <MobileBanner>[
              MobileBanner(
                id: 1,
                name: 'Campaign one',
                title: 'Mobile deals are live',
                subtitle: 'Tap into Odoo products from a native storefront.',
                imageUrl: '',
                actionKind: 'product',
                productTemplateId: 42,
              ),
              MobileBanner(
                id: 2,
                name: 'Campaign two',
                title: 'Checkout in minutes',
                subtitle: 'A smooth cart and payment flow.',
                imageUrl: '',
                actionKind: 'url',
              ),
            ],
            onSelectProduct: (id) {
              selectedProductId = id;
            },
          ),
        ),
      ),
    );

    expect(find.byType(PageView), findsOneWidget);
    expect(find.text('Mobile deals are live'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(2));

    await tester.tap(find.text('Mobile deals are live'));
    expect(selectedProductId, 42);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('category section renders handoff action chips',
      (WidgetTester tester) async {
    var selectedCategoryId = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryScroller(
            categories: <MobileCategory>[
              MobileCategory(
                id: 7,
                name: 'Desks',
                description: '',
                imageUrl: '/web/image/product.public.category/7/cover_image',
              ),
              MobileCategory(
                id: 8,
                name: 'Storage',
                description: '',
                imageUrl: '',
              ),
            ],
            onOpenCategory: (id) {
              selectedCategoryId = id;
            },
          ),
        ),
      ),
    );

    expect(find.byType(CategoryScroller), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(2));
    expect(find.text('Desks'), findsOneWidget);

    await tester.tap(find.text('Desks'));
    expect(selectedCategoryId, 7);
  });

  testWidgets('home search bar submits a catalog query',
      (WidgetTester tester) async {
    var submittedQuery = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeSearchBar(
            onSearch: (query) {
              submittedQuery = query;
            },
          ),
        ),
      ),
    );

    expect(find.text('Search products...'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'desk');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    expect(submittedQuery, 'desk');
  });

  test('local web bootstrap clears caches without registering a service worker',
      () {
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();
    final index = File('web/index.html').readAsStringSync();

    expect(bootstrap, contains('clearFlutterCaches'));
    expect(bootstrap, contains('getRegistrations'));
    expect(bootstrap, contains('caches.delete'));
    expect(bootstrap, isNot(contains('serviceWorkerSettings')));
    expect(index, contains('synthoshop-icons-20260417'));
  });
}

ManagedNavigationItem _navItem({
  required int id,
  required String label,
  required String icon,
  required String? tabKey,
  String targetKind = 'tab',
}) {
  return ManagedNavigationItem(
    id: id,
    label: label,
    icon: icon,
    targetKind: targetKind,
    tabKey: tabKey,
    categoryId: null,
    contentPageId: null,
    externalUrl: null,
  );
}

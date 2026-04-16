import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';
import '../utils/app_utils.dart';
import 'home_screen.dart';
import 'catalog_screen.dart';
import 'brands_screen.dart';
import 'barcode_screen.dart';
import 'cart_screen.dart';
import 'account_screen.dart';
import 'product_detail_screen.dart';
import 'checkout_flow_screen.dart';
import 'wishlist_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appState});

  final AppState appState;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  AppTab _activeTab = AppTab.home;
  int? _selectedProductId;
  int? _selectedCategoryId;
  int? _selectedBrandId;
  String? _selectedBrandName;
  String _catalogSearch = '';
  bool _checkoutVisible = false;
  Uri? _incomingCheckoutUri;
  bool _initializing = true;
  String? _initializationError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await widget.appState.initialize();
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _applyIncomingCheckoutUri(initialUri);
      }
      _linkSubscription =
          _appLinks.uriLinkStream.listen(_applyIncomingCheckoutUri);
    } catch (error) {
      _initializationError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  void _applyIncomingCheckoutUri(Uri uri) {
    if (!uri.toString().contains('checkout/result')) {
      return;
    }
    setState(() {
      _incomingCheckoutUri = uri;
      _checkoutVisible = true;
      _selectedProductId = null;
      _activeTab = AppTab.cart;
    });
  }

  void _openProduct(int productId) {
    setState(() {
      _selectedProductId = productId;
      _checkoutVisible = false;
    });
  }

  void _openCategory(int categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedBrandId = null;
      _selectedBrandName = null;
      _catalogSearch = '';
      _selectedProductId = null;
      _checkoutVisible = false;
      _activeTab = AppTab.shop;
    });
  }

  void _openBrand(ProductBrand brand) {
    setState(() {
      _selectedBrandId = brand.id;
      _selectedBrandName = brand.name;
      _selectedCategoryId = null;
      _catalogSearch = '';
      _selectedProductId = null;
      _checkoutVisible = false;
      _activeTab = AppTab.shop;
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.appState,
      builder: (context, _) {
        if (_initializing) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_initializationError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.error_outline_rounded,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 24),
                    const Text(
                      'Unable to connect',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _initializationError!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _initializing = true;
                          _initializationError = null;
                        });
                        _bootstrap();
                      },
                      child: const Text('Retry connection'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final bool showingDetail =
            _checkoutVisible || _selectedProductId != null;
        final int cartCount = widget.appState.cart.cartQuantity.round();
        final bootstrap = widget.appState.bootstrap;
        final navigationItems = _buildNavigationItems(bootstrap);

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _AppHeader(
                  showingDetail: showingDetail,
                  cartCount: cartCount,
                  title: bootstrap?.app.name ?? 'Syntho Shop',
                  hostLabel: bootstrap?.website.baseUrl.isNotEmpty == true
                      ? bootstrap!.website.baseUrl
                          .replaceFirst(RegExp(r'^https?://'), '')
                      : AppConfig.trimmedBaseUrl
                          .replaceFirst(RegExp(r'^https?://'), ''),
                  onBack: () {
                    setState(() {
                      if (_checkoutVisible) {
                        _checkoutVisible = false;
                        _incomingCheckoutUri = null;
                      } else {
                        _selectedProductId = null;
                      }
                    });
                  },
                  onOpenCart: () {
                    setState(() {
                      _activeTab = AppTab.cart;
                      _selectedProductId = null;
                      _checkoutVisible = false;
                    });
                  },
                  onOpenWishlist: () {
                    setState(() {
                      _activeTab = AppTab.wishlist;
                      _selectedProductId = null;
                      _checkoutVisible = false;
                    });
                  },
                ),
                if (bootstrap?.app.maintenanceMode == true)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade800),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              bootstrap?.app.maintenanceMessage ??
                                  'Under maintenance',
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(child: _buildContent(context)),
              ],
            ),
          ),
          bottomNavigationBar: showingDetail
              ? null
              : NavigationBar(
                  selectedIndex: _selectedNavigationIndex(navigationItems),
                  onDestinationSelected: (index) {
                    final item = navigationItems[index];
                    setState(() {
                      _handleNavigationTap(item);
                      _selectedProductId = null;
                      _checkoutVisible = false;
                    });
                  },
                  destinations: navigationItems
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(iconForName(item.icon, outlined: true)),
                          selectedIcon:
                              Icon(iconForName(item.icon, outlined: false)),
                          label: item.label,
                        ),
                      )
                      .toList(),
                ),
        );
      },
    );
  }

  List<ManagedNavigationItem> _buildNavigationItems(
      BootstrapPayload? bootstrap) {
    final configured = (bootstrap?.navigation ?? <ManagedNavigationItem>[])
        .where((item) => item.targetKind == 'tab')
        .toList();
    final items = configured.isNotEmpty
        ? List<ManagedNavigationItem>.from(configured)
        : <ManagedNavigationItem>[
            ManagedNavigationItem(
              id: 1,
              label: 'Home',
              icon: 'home',
              targetKind: 'tab',
              tabKey: 'home',
              categoryId: null,
              contentPageId: null,
              externalUrl: null,
            ),
            ManagedNavigationItem(
              id: 2,
              label: 'Shop',
              icon: 'shop',
              targetKind: 'tab',
              tabKey: 'shop',
              categoryId: null,
              contentPageId: null,
              externalUrl: null,
            ),
            ManagedNavigationItem(
              id: 3,
              label: 'Cart',
              icon: 'cart',
              targetKind: 'tab',
              tabKey: 'cart',
              categoryId: null,
              contentPageId: null,
              externalUrl: null,
            ),
            ManagedNavigationItem(
              id: 4,
              label: 'Account',
              icon: 'account',
              targetKind: 'tab',
              tabKey: 'account',
              categoryId: null,
              contentPageId: null,
              externalUrl: null,
            ),
          ];
    void addIfMissing(String tabKey, String label, String icon) {
      if (items.any((item) => item.tabKey == tabKey)) return;
      items.add(ManagedNavigationItem(
        id: 1000 + items.length,
        label: label,
        icon: icon,
        targetKind: 'tab',
        tabKey: tabKey,
        categoryId: null,
        contentPageId: null,
        externalUrl: null,
      ));
    }

    addIfMissing('brands', 'Brands', 'brands');
    addIfMissing('scan', 'Scan', 'scan');
    return items;
  }

  int _selectedNavigationIndex(List<ManagedNavigationItem> items) {
    final index = items.indexWhere((item) => item.tabKey == _activeTab.name);
    return index >= 0 ? index : 0;
  }

  void _handleNavigationTap(ManagedNavigationItem item) {
    switch (item.tabKey) {
      case 'shop':
        _activeTab = AppTab.shop;
        break;
      case 'cart':
        _activeTab = AppTab.cart;
        break;
      case 'account':
        _activeTab = AppTab.account;
        break;
      case 'brands':
        _activeTab = AppTab.brands;
        break;
      case 'scan':
        _activeTab = AppTab.scan;
        break;
      case 'wishlist':
        _activeTab = AppTab.wishlist;
        break;
      case 'home':
      default:
        _activeTab = AppTab.home;
        break;
    }
  }

  Widget _buildContent(BuildContext context) {
    if (_checkoutVisible) {
      return CheckoutFlowScreen(
        appState: widget.appState,
        incomingUri: _incomingCheckoutUri,
        onIncomingUriHandled: () {
          setState(() {
            _incomingCheckoutUri = null;
          });
        },
        onGoToAccount: () {
          setState(() {
            _checkoutVisible = false;
            _incomingCheckoutUri = null;
            _activeTab = AppTab.account;
          });
        },
      );
    }

    if (_selectedProductId != null) {
      return ProductDetailScreen(
        appState: widget.appState,
        productTemplateId: _selectedProductId!,
      );
    }

    switch (_activeTab) {
      case AppTab.shop:
        return CatalogScreen(
          appState: widget.appState,
          searchSeed: _catalogSearch,
          categorySeed: _selectedCategoryId,
          brandSeed: _selectedBrandId,
          brandName: _selectedBrandName,
          onSelectProduct: _openProduct,
        );
      case AppTab.brands:
        return BrandsScreen(
          appState: widget.appState,
          onSelectBrand: _openBrand,
        );
      case AppTab.scan:
        return BarcodeScreen(
          appState: widget.appState,
          onProductFound: _openProduct,
        );
      case AppTab.cart:
        return CartScreen(
          appState: widget.appState,
          onStartCheckout: () {
            setState(() {
              _checkoutVisible = true;
              _selectedProductId = null;
              _incomingCheckoutUri = null;
            });
          },
        );
      case AppTab.account:
        return AccountScreen(appState: widget.appState);
      case AppTab.wishlist:
        return WishlistScreen(
          appState: widget.appState,
          onSelectProduct: _openProduct,
          onGoToAccount: () {
            setState(() {
              _activeTab = AppTab.account;
            });
          },
        );
      case AppTab.home:
        return HomeScreen(
          appState: widget.appState,
          onSelectProduct: _openProduct,
          onOpenCategory: _openCategory,
        );
    }
  }
}

class _AppHeader extends StatelessWidget {
  const _AppHeader({
    required this.showingDetail,
    required this.cartCount,
    required this.title,
    required this.hostLabel,
    required this.onBack,
    required this.onOpenCart,
    required this.onOpenWishlist,
  });

  final bool showingDetail;
  final int cartCount;
  final String title;
  final String hostLabel;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;
  final VoidCallback onOpenWishlist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: showingDetail
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hostLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!showingDetail)
            IconButton.filledTonal(
              onPressed: onOpenWishlist,
              icon: const Icon(Icons.favorite_border),
            ),
          if (!showingDetail) const SizedBox(width: 8),
          if (!showingDetail)
            Badge.count(
              count: cartCount,
              isLabelVisible: cartCount > 0,
              child: IconButton.filledTonal(
                onPressed: onOpenCart,
                icon: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
        ],
      ),
    );
  }
}

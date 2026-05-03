import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/mobile_models.dart';
import '../services/odoo_api.dart';
import '../theme/color_utils.dart';

class AppState extends ChangeNotifier {
  AppState({OdooApi? api}) : _api = api ?? OdooApi();

  final OdooApi _api;

  BootstrapPayload? bootstrap;
  HomePayload? home;
  CartPayload cart = CartPayload.empty();
  AccountPayload? account;
  WishlistPayload? wishlist;
  NotificationPayload notifications = NotificationPayload.empty();
  Set<int> wishlistIds = <int>{};

  bool homeLoading = false;
  bool cartLoading = false;
  bool accountLoading = false;
  bool wishlistLoading = false;
  bool notificationsLoading = false;

  OdooApi get api => _api;

  Color? get primaryColor => parseHexColor(bootstrap?.app.primaryColor);
  Color? get accentColor => parseHexColor(bootstrap?.app.accentColor);

  Future<void> initialize() async {
    await Future.wait<void>(<Future<void>>[
      refreshBootstrap(),
      refreshHome(),
      refreshCart(),
      refreshAccount(silent: true),
      loadWishlist(silent: true),
      loadNotifications(silent: true),
    ]);
  }

  Future<void> refreshBootstrap() async {
    homeLoading = true;
    notifyListeners();
    try {
      bootstrap = await _api.getBootstrap();
    } finally {
      homeLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshHome() async {
    homeLoading = true;
    notifyListeners();
    try {
      home = await _api.getHome();
    } finally {
      homeLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshCart() async {
    cartLoading = true;
    notifyListeners();
    try {
      cart = await _api.getCart();
    } finally {
      cartLoading = false;
      notifyListeners();
    }
  }

  Future<void> addToCart(int productId, {double quantity = 1}) async {
    cartLoading = true;
    notifyListeners();
    try {
      cart = await _api.addToCart(productId, quantity: quantity);
    } finally {
      cartLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCartLine(int lineId, double quantity) async {
    cartLoading = true;
    notifyListeners();
    try {
      cart = await _api.updateCartLine(lineId, quantity);
    } finally {
      cartLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshAccount({bool silent = false}) async {
    if (!silent) {
      accountLoading = true;
      notifyListeners();
    }
    try {
      account = await _api.getAccount();
    } catch (_) {
      account = null;
    } finally {
      accountLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String login, String password) async {
    accountLoading = true;
    notifyListeners();
    try {
      await _api.authenticate(login, password);
      account = await _api.getAccount();
      await loadWishlist(silent: true);
      await loadNotifications(silent: true);
    } finally {
      accountLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle(String idToken) async {
    accountLoading = true;
    notifyListeners();
    try {
      account = await _api.loginWithGoogle(idToken);
      await loadWishlist(silent: true);
      await loadNotifications(silent: true);
    } finally {
      accountLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    accountLoading = true;
    notifyListeners();
    try {
      await _api.logout();
      account = null;
      wishlist = null;
      notifications = NotificationPayload.empty();
      wishlistIds = <int>{};
    } finally {
      accountLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWishlist({bool silent = false}) async {
    if (!silent) {
      wishlistLoading = true;
      notifyListeners();
    }
    try {
      wishlist = await _api.getWishlist();
      wishlistIds = wishlist!.productIds;
    } catch (_) {
      wishlist = null;
      wishlistIds = <int>{};
    } finally {
      wishlistLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleWishlist(int productId) async {
    wishlistLoading = true;
    notifyListeners();
    try {
      final payload = await _api.toggleWishlist(productId);
      wishlist = payload;
      wishlistIds = payload.productIds;
      return payload.wished ?? wishlistIds.contains(productId);
    } finally {
      wishlistLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadNotifications({bool silent = false}) async {
    if (!silent) {
      notificationsLoading = true;
      notifyListeners();
    }
    try {
      notifications = await _api.getNotifications();
    } catch (_) {
      notifications = NotificationPayload.empty();
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }

  Future<void> markNotificationsRead({List<int>? notificationIds}) async {
    notificationsLoading = true;
    notifyListeners();
    try {
      notifications = await _api.markNotificationsRead(
        notificationIds: notificationIds,
      );
    } finally {
      notificationsLoading = false;
      notifyListeners();
    }
  }

  void addForegroundNotification(AppNotification notification) {
    notifications = NotificationPayload(
      items: <AppNotification>[notification, ...notifications.items],
      unreadCount: notifications.unreadCount + 1,
    );
    notifyListeners();
  }

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }
}

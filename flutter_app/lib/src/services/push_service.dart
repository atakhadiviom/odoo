import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/mobile_models.dart';
import '../state/app_state.dart';

class PushService {
  static FirebaseMessaging? _messaging;

  static Future<void> initialize(AppState appState) async {
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp();

      final messaging = FirebaseMessaging.instance;
      _messaging = messaging;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        await registerCurrentDevice(appState);
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        appState.addForegroundNotification(
          AppNotification(
            id: DateTime.now().millisecondsSinceEpoch,
            title: notification?.title ?? 'New notification',
            body: notification?.body ?? '',
            type: message.data['type'] ?? message.data['action'] ?? 'info',
            data: message.data,
            isRead: false,
            pushSent: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      });

      messaging.onTokenRefresh.listen((token) async {
        await appState.api.registerDevice(
          token: token,
          platform: Platform.isIOS ? 'ios' : 'android',
        );
      });
    } catch (e) {
      print('Error initializing PushService: $e');
    }
  }

  static Future<void> registerCurrentDevice(AppState appState) async {
    if (kIsWeb) return;
    final messaging = _messaging;
    if (messaging == null) return;

    final token = await messaging.getToken();
    if (token == null) return;
    await appState.api.registerDevice(
      token: token,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Push notification delivery (FCM) — cleared of Supabase backend references.
/// Ready to be wired up with your Firebase Firestore device tokens collection.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      FirebaseMessaging.onMessage.listen((message) {
        final notification = message.notification;
        if (notification == null) return;
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'play_smart_default',
              'Play Smart notifications',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      });

      _initialized = true;
    } catch (e) {
      debugPrint('PushNotificationService: not available yet ($e)');
    }
  }

  /// Register this device's FCM token.
  Future<void> registerToken(String userId) async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _upsertToken(userId, token);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _upsertToken(userId, newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationService.registerToken failed: $e');
    }
  }

  Future<void> _upsertToken(String userId, String token) async {
    // TODO: Upsert device token to Firebase Firestore device_tokens collection
  }

  /// Remove this device's token on sign-out.
  Future<void> unregisterToken() async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      // TODO: Delete token from Firebase Firestore device_tokens collection
    } catch (e) {
      debugPrint('PushNotificationService.unregisterToken failed: $e');
    }
  }
}

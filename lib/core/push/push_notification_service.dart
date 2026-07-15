import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:play_smart/core/supabase/supabase_config.dart';

/// Push notification delivery (FCM) for the notifications created by
/// `NotificationRepository` (see `supabase/functions/send-push-notification`
/// for the server side).
///
/// **Requires a one-time manual setup step this class cannot do on its own:**
/// run `flutterfire configure` (needs your Firebase project login) to
/// generate `lib/firebase_options.dart` and the native config files
/// (`google-services.json` / `GoogleService-Info.plist`). Until that's done,
/// [initialize] fails silently and the rest of the app is unaffected — no
/// notification badge/list functionality depends on this.
class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    try {
      // TODO(flutterfire-configure): once `flutterfire configure` has been
      // run, pass `options: DefaultFirebaseOptions.currentPlatform` here
      // (import 'package:play_smart/firebase_options.dart').
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

      // FCM delivers silently while the app is foregrounded — show it
      // ourselves so the user sees something instead of nothing.
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
      // Firebase isn't configured yet (no firebase_options.dart / native
      // config) — push notifications are unavailable, everything else works.
      debugPrint('PushNotificationService: not available yet ($e)');
    }
  }

  /// Register this device's FCM token against [userId]. Call after sign-in.
  Future<void> registerToken(String userId) async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await _upsertToken(userId, token);

      // Keep the row current if FCM rotates the token later in the session.
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _upsertToken(userId, newToken);
      });
    } catch (e) {
      debugPrint('PushNotificationService.registerToken failed: $e');
    }
  }

  Future<void> _upsertToken(String userId, String token) async {
    await supabase.from('device_tokens').upsert(
      {
        'user_id': userId,
        'token': token,
        'platform': defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      },
      onConflict: 'token',
    );
  }

  /// Remove this device's token so a shared/logged-out device stops
  /// receiving pushes meant for the previous account. Call on sign-out.
  Future<void> unregisterToken() async {
    if (!_initialized) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;
      await supabase.from('device_tokens').delete().eq('token', token);
    } catch (e) {
      debugPrint('PushNotificationService.unregisterToken failed: $e');
    }
  }
}

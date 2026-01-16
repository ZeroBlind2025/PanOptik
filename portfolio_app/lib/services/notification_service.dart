import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_service.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final _api = ApiService();

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _updateFcmToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateFcmToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);
  }

  static Future<void> _updateFcmToken(String token) async {
    try {
      await _api.post('/users/fcm-token', data: {'token': token});
    } catch (e) {
      // Ignore errors - will retry on next token refresh
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground notification
    // Could show a local notification or update UI
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background notification
    // This runs in a separate isolate
  }
}

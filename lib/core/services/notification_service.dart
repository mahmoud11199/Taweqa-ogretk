import 'dart:io' show Platform;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/supabase_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static FlutterLocalNotificationsPlugin get localNotifications => _localNotifications;
  static String? _fcmToken;
  static bool _initialized = false;
  static int _notificationId = 0;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    _fcmToken = await messaging.getToken();
    await _saveToken(_fcmToken);

    messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message);
    });

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _saveToken(String? token) async {
    if (token == null) return;
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final platform = Platform.isIOS ? 'ios' : 'android';
      await SupabaseConfig.client.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platform,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final title = message.notification?.title ?? 'عدادي مَرِنْ';
    final body = message.notification?.body ?? '';
    await _showLocalNotification(title, body, message.data);
  }

  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    await _showLocalNotification(
      message.notification?.title ?? 'عدادي مَرِنْ',
      message.notification?.body ?? '',
      message.data,
    );
  }

  static Future<void> _showLocalNotification(String title, String body, Map<String, dynamic> data) async {
    _notificationId++;
    const androidDetails = AndroidNotificationDetails(
      'taweqa_notifications',
      'إشعارات التطبيق',
      channelDescription: 'إشعارات الرحلات والتحديثات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _localNotifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
      payload: data['type'] as String?,
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    _handleNavigation(response.payload);
  }

  static void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'] as String?;
    _handleNavigation(type);
  }

  static void _handleNavigation(String? type) {
    if (type == null) return;
    // Navigation handled via global navigator key or direct push
    // Types: 'new_ride', 'chat_message', 'subscription', 'promotion'
  }

  static Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  static Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
  }
}

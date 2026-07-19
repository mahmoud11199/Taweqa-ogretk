import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';

class InAppNotificationService {
  static RealtimeChannel? _channel;
  static bool _initialized = false;
  static int _notificationId = 0;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<void> startListening(String userId) async {
    await stopListening();
    _channel = SupabaseConfig.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          table: 'notifications',
          schema: 'public',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
          callback: (payload) {
            final data = payload.newRecord;
            final title = data['title'] as String? ?? 'عدادي مَرِنْ';
            final body = data['body'] as String? ?? '';
            _showNotification(title, body);
          },
        )
        .subscribe();
  }

  static Future<void> stopListening() async {
    await _channel?.unsubscribe();
    _channel = null;
  }

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
  }) async {
    try {
      await SupabaseConfig.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'is_read': false,
      }).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<void> _showNotification(String title, String body) async {
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
    await NotificationService.localNotifications.show(
      id: _notificationId,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/supabase_config.dart';

class DeviceUtils {
  static Map<String, dynamic>? _deviceInfo;

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    if (_deviceInfo != null) return _deviceInfo!;
    _deviceInfo = {
      'platform': defaultTargetPlatform.name,
      'isWeb': kIsWeb,
      'app_version': '2.0.0',
    };
    return _deviceInfo!;
  }

  static Future<void> logToServer(String message, {String level = 'info', Map<String, dynamic>? extra}) async {
    try {
      await SupabaseConfig.client.from('server_logs').insert({
        'message': message,
        'level': level,
        'extra': extra,
        'user_id': SupabaseConfig.client.auth.currentUser?.id,
      });
    } catch (_) {}
  }
}

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 500)});

  void call(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class BackgroundLocationService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await FlutterBackgroundService().configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'taweqa_location',
        initialNotificationTitle: 'عدادي مَرِنْ',
        initialNotificationContent: 'تتبع الموقع نشط',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) async {
    if (service is AndroidServiceInstance) {
      await service.setAsForegroundService();
    }

    var running = true;

    service.on('stopService').listen((_) {
      running = false;
      if (service is AndroidServiceInstance) {
        service.stopSelf();
      }
    });

    // The background isolate never runs SupabaseConfig.init(), so build a
    // dedicated client from the same URL/anon key.
    final bgClient = SupabaseClient(
      AppConstants.supabaseUrl,
      AppConstants.supabaseAnonKey,
    );

    while (running) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        try {
          final user = bgClient.auth.currentUser;
          if (user != null) {
            await bgClient.rpc('update_driver_location', params: {
              'p_driver_id': user.id,
              'p_lat': position.latitude,
              'p_lng': position.longitude,
            });
          }
        } catch (_) {}
      } catch (_) {}

      if (running) {
        await Future.delayed(const Duration(seconds: 20));
      }
    }
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static Future<void> start() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}

import '../config/supabase_config.dart';

class SosService {
  static Future<bool> sendAlert({
    required String userId,
    required double lat,
    required double lng,
    String? message,
  }) async {
    try {
      await SupabaseConfig.client.from('sos_alerts').insert({
        'user_id': userId,
        'lat': lat,
        'lng': lng,
        'message': message ?? 'طلب نجدة',
        'status': 'active',
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchActiveAlerts() async {
    final data = await SupabaseConfig.client.rpc('get_sos_alerts');
    return (data as List).cast<Map<String, dynamic>>();
  }

  static Future<void> resolveAlert(String alertId) async {
    await SupabaseConfig.client
        .from('sos_alerts')
        .update({'status': 'resolved'})
        .eq('id', alertId);
  }
}

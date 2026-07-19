import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/admin_models.dart';

class AdminRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<AdminStats> fetchStats() async {
    final response = await _client.rpc('get_admin_stats');
    return AdminStats.fromMap(response as Map<String, dynamic>);
  }

  Future<List<AdminDriver>> fetchDrivers() async {
    final response = await _client
        .from('drivers')
        .select('''
          id, is_available, driver_type, car_model, car_plate,
          profiles!inner(full_name, phone, banned)
        ''')
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((e) => AdminDriver.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<List<dynamic>> fetchPassengers() async {
    final response = await _client
        .from('profiles')
        .select('id, full_name, phone, email, created_at')
        .eq('role', 'passenger')
        .order('created_at', ascending: false);
    return response as List<dynamic>;
  }

  Future<List<dynamic>> fetchAllTrips() async {
    final response = await _client
        .from('trips')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return response as List<dynamic>;
  }

  Future<List<DriverApplication>> fetchDriverApplications() async {
    final response = await _client
        .from('driver_applications')
        .select()
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((e) => DriverApplication.fromMap(e)).toList();
  }

  Future<void> approveDriver(String userId) async {
    await _client.from('driver_applications').update({'status': 'approved'}).eq('user_id', userId);
    await _client.from('drivers').update({'is_available': true}).eq('id', userId);
  }

  Future<void> rejectDriver(String userId) async {
    await _client.from('driver_applications').update({'status': 'rejected'}).eq('user_id', userId);
  }

  Future<void> toggleDriverBan(String userId, bool banned) async {
    await _client.from('profiles').update({'banned': banned}).eq('id', userId);
  }

  Future<Map<String, double>> fetchAppSettings() async {
    final response = await _client
        .from('app_settings')
        .select()
        .maybeSingle();
    if (response != null) {
      final map = response;
      return {
        'pricing_per_km': (map['pricing_per_km'] as num?)?.toDouble() ?? 3.5,
        'pricing_per_min': (map['pricing_per_min'] as num?)?.toDouble() ?? 0.5,
        'base_fare': (map['base_fare'] as num?)?.toDouble() ?? 5.0,
        'commission_rate': (map['commission_rate'] as num?)?.toDouble() ?? 0.15,
      };
    }
    return {};
  }

  Future<void> updateAppSettings(Map<String, double> settings) async {
    await _client.from('app_settings').upsert(settings);
  }
}

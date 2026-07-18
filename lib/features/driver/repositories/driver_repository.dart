import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../models/trip_model.dart';

class DriverRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> fetchDriverProfile(String userId) async {
    final response = await _client
        .from('drivers')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (response != null) return response;
    throw Exception('Driver profile not found');
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await _client
        .from('drivers')
        .update({'is_available': isAvailable})
        .eq('id', userId);
  }

  Future<void> updateLocation(String userId, double lat, double lng) async {
    await _client.rpc('update_driver_location', params: {
      'p_driver_id': userId,
      'p_lat': lat,
      'p_lng': lng,
    });
  }

  Future<Trip> createTrip({
    required String driverId,
    required double startLat,
    required double startLng,
  }) async {
    final response = await _client.from('trips').insert({
      'driver_id': driverId,
      'start_lat': startLat,
      'start_lng': startLng,
      'status': 'active',
    }).select().single();
    return Trip.fromMap(response);
  }

  Future<Trip> endTrip({
    required String tripId,
    required double endLat,
    required double endLng,
    required double distanceKm,
    required double durationMin,
    required double fare,
    required double driverCut,
  }) async {
    final response = await _client.from('trips').update({
      'end_lat': endLat,
      'end_lng': endLng,
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'fare': fare,
      'driver_cut': driverCut,
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    }).eq('id', tripId).select().single();
    return Trip.fromMap(response);
  }

  Future<List<Trip>> fetchTripHistory(String driverId) async {
    final response = await _client
        .from('trips')
        .select()
        .eq('driver_id', driverId)
        .order('created_at', ascending: false)
        .limit(50);
    final list = response as List<dynamic>;
    return list.map((e) => Trip.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> fetchEarnings(String driverId) async {
    final response = await _client
        .from('trips')
        .select('fare, driver_cut, created_at')
        .eq('driver_id', driverId)
        .eq('status', 'completed');
    final trips = response as List<dynamic>;
    double totalFare = 0;
    double totalCut = 0;
    for (final t in trips) {
      totalFare += (t['fare'] as num?)?.toDouble() ?? 0;
      totalCut += (t['driver_cut'] as num?)?.toDouble() ?? 0;
    }
    return {'total_fare': totalFare, 'total_cut': totalCut, 'count': trips.length};
  }

  Future<Map<String, dynamic>> fetchRoute(
      double startLat, double startLng, double endLat, double endLng) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson&steps=true';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to fetch route');
  }

  double calculateFare(double distanceKm, double durationMin) {
    const baseFare = AppConstants.pricingBaseFare;
    const perKm = AppConstants.pricingPerKm;
    const perMin = AppConstants.pricingPerMin;
    return baseFare + (distanceKm * perKm) + (durationMin * perMin);
  }

  double calculateDriverCut(double fare) {
    return fare * (1 - AppConstants.appCommissionRate);
  }
}

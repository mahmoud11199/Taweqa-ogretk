import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../models/ride_request.dart';

class PassengerRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchNearbyDrivers(double lat, double lng) async {
    final response = await _client.rpc('get_nearby_drivers', params: {
      'p_lat': lat,
      'p_lng': lng,
      'p_radius_km': 10,
    });
    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<RideRequest> requestRide({
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    double? destLat,
    double? destLng,
    String? destAddress,
  }) async {
    final response = await _client.from('ride_requests').insert({
      'passenger_id': passengerId,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_address': pickupAddress,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'dest_address': destAddress,
      'status': 'pending',
    }).select().single();
    return RideRequest.fromMap(response);
  }

  Future<RideRequest> fetchActiveRequest(String passengerId) async {
    final response = await _client
        .from('ride_requests')
        .select()
        .eq('passenger_id', passengerId)
        .or('status.eq.pending,status.eq.accepted')
        .maybeSingle();
    if (response != null) return RideRequest.fromMap(response);
    throw Exception('No active request');
  }

  Future<void> cancelRequest(String requestId) async {
    await _client
        .from('ride_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId);
  }

  Future<List<RideRequest>> fetchHistory(String passengerId) async {
    final response = await _client
        .from('ride_requests')
        .select()
        .eq('passenger_id', passengerId)
        .or('status.eq.completed,status.eq.cancelled')
        .order('created_at', ascending: false)
        .limit(50);
    final list = response as List<dynamic>;
    return list.map((e) => RideRequest.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<void> rateDriver(String requestId, double rating, {String? review}) async {
    await _client.from('ride_requests').update({
      'rating': rating,
      if (review != null) 'review': review,
    }).eq('id', requestId);
  }

  Future<Map<String, dynamic>> estimateFare(
      double pickupLat, double pickupLng, double destLat, double destLng) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/$pickupLng,$pickupLat;$destLng,$destLat?overview=false';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List<dynamic>;
      if (routes.isNotEmpty) {
        final route = routes[0] as Map<String, dynamic>;
        final distanceKm = (route['distance'] as num) / 1000;
        final durationMin = (route['duration'] as num) / 60;
        const baseFare = AppConstants.pricingBaseFare;
        const perKm = AppConstants.pricingPerKm;
        const perMin = AppConstants.pricingPerMin;
        final fare = baseFare + (distanceKm * perKm) + (durationMin * perMin);
        return {
          'distance_km': distanceKm,
          'duration_min': durationMin,
          'estimated_fare': fare,
        };
      }
    }
    throw Exception('Failed to estimate fare');
  }
}

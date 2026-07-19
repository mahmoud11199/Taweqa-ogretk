import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/trip_passenger.dart';
import '../../../core/models/vehicle_category.dart';
import '../../../core/services/local_database.dart';
import '../../../core/utils/cache_helper.dart';
import '../models/ride_request.dart';

class PassengerRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> fetchNearbyDrivers(double lat, double lng) async {
    if (CacheHelper.isOnline) {
      try {
        final response = await _client.rpc('get_nearby_drivers', params: {
          'p_lat': lat,
          'p_lng': lng,
          'p_radius_km': 10,
        });
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      } catch (_) {
        final cached = await LocalDatabase.query('drivers', where: 'is_available = 1');
        return cached;
      }
    }
    final cached = await LocalDatabase.query('drivers', where: 'is_available = 1');
    return cached;
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
    final data = {
      'passenger_id': passengerId,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_address': pickupAddress,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'dest_address': destAddress,
      'status': 'pending',
    };
    if (CacheHelper.isOnline) {
      try {
        final response = await _client.from('ride_requests').insert(data).select().single();
        await LocalDatabase.insert('ride_requests', response);
        return RideRequest.fromMap(response);
      } catch (_) {}
    }
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localData = {...data, 'id': tempId, 'created_at': DateTime.now().toIso8601String()};
    await LocalDatabase.insert('ride_requests', localData);
    await LocalDatabase.addToSyncQueue('ride_requests', 'insert', tempId, data);
    return RideRequest.fromMap(localData);
  }

  Future<RideRequest> fetchActiveRequest(String passengerId) async {
    if (CacheHelper.isOnline) {
      try {
        final response = await _client
            .from('ride_requests')
            .select()
            .eq('passenger_id', passengerId)
            .or('status.eq.pending,status.eq.accepted')
            .maybeSingle();
        if (response != null) {
          await LocalDatabase.insert('ride_requests', response);
          return RideRequest.fromMap(response);
        }
      } catch (_) {}
    }
    final cached = await LocalDatabase.query('ride_requests',
        where: 'passenger_id = ? AND (status = ? OR status = ?)',
        whereArgs: [passengerId, 'pending', 'accepted'],
        limit: 1);
    if (cached.isNotEmpty) return RideRequest.fromMap(cached.first);
    throw Exception('No active request');
  }

  Future<void> cancelRequest(String requestId) async {
    await CacheHelper.writeWithSync(
      table: 'ride_requests',
      id: requestId,
      data: {'id': requestId, 'status': 'cancelled'},
      onlineWrite: () => _client
          .from('ride_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId),
    );
  }

  Future<RideRequest?> fetchRideRequestById(String requestId) async {
    if (CacheHelper.isOnline) {
      try {
        final response = await _client
            .from('ride_requests')
            .select()
            .eq('id', requestId)
            .maybeSingle();
        if (response != null) return RideRequest.fromMap(response);
      } catch (_) {}
    }
    final cached = await LocalDatabase.query('ride_requests',
        where: 'id = ?', whereArgs: [requestId], limit: 1);
    if (cached.isNotEmpty) return RideRequest.fromMap(cached.first);
    return null;
  }

  Future<List<RideRequest>> fetchHistory(String passengerId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'ride_requests',
      onlineFetch: () async {
        final response = await _client
            .from('ride_requests')
            .select()
            .eq('passenger_id', passengerId)
            .or('status.eq.completed,status.eq.cancelled')
            .order('created_at', ascending: false)
            .limit(50);
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    return rows.map((e) => RideRequest.fromMap(e)).toList();
  }

  Future<void> rateDriver(String requestId, double rating, {String? review}) async {
    final Map<String, dynamic> updates = {'rating': rating};
    if (review != null) updates['review'] = review;
    await CacheHelper.writeWithSync(
      table: 'ride_requests',
      id: requestId,
      data: {'id': requestId, ...updates},
      onlineWrite: () => _client
          .from('ride_requests')
          .update(updates)
          .eq('id', requestId),
    );
  }

  Future<RideRequest> scheduleRide({
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    double? destLat,
    double? destLng,
    String? destAddress,
    required DateTime scheduledAt,
  }) async {
    final data = {
      'passenger_id': passengerId,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_address': pickupAddress,
      'status': 'scheduled',
      'scheduled_at': scheduledAt.toIso8601String(),
    };
    if (destLat != null) data['dest_lat'] = destLat;
    if (destLng != null) data['dest_lng'] = destLng;
    if (destAddress != null) data['dest_address'] = destAddress;

    if (CacheHelper.isOnline) {
      try {
        final response = await _client.from('ride_requests').insert(data).select().single();
        await LocalDatabase.insert('ride_requests', response);
        return RideRequest.fromMap(response);
      } catch (_) {}
    }
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    final localData = {...data, 'id': tempId, 'created_at': DateTime.now().toIso8601String()};
    await LocalDatabase.insert('ride_requests', localData);
    await LocalDatabase.addToSyncQueue('ride_requests', 'insert', tempId, data);
    return RideRequest.fromMap(localData);
  }

  Future<List<RideRequest>> fetchScheduledTrips(String passengerId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'ride_requests',
      onlineFetch: () async {
        final response = await _client
            .from('ride_requests')
            .select()
            .eq('passenger_id', passengerId)
            .eq('status', 'scheduled')
            .order('scheduled_at', ascending: true);
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    return rows.map((e) => RideRequest.fromMap(e)).toList();
  }

  Future<TripPassenger> joinSharedRide({
    required String shareCode,
    required String passengerId,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    double? destLat,
    double? destLng,
    String? destAddress,
  }) async {
    final trip = await _client
        .from('trips')
        .select('id, driver_id')
        .eq('share_code', shareCode)
        .eq('status', 'active')
        .maybeSingle();
    if (trip == null) throw Exception('لم يتم العثور على رحلة بهذا الكود');
    final response = await _client.from('trip_passengers').insert({
      'trip_id': trip['id'],
      'passenger_id': passengerId,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'pickup_address': pickupAddress,
      'dest_lat': destLat,
      'dest_lng': destLng,
      'dest_address': destAddress,
      'status': 'pending',
    }).select().single();
    return TripPassenger.fromMap(response);
  }

  Future<Map<String, dynamic>> estimateFare(
      double pickupLat, double pickupLng, double destLat, double destLng, {VehicleCategory? category}) async {
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
        final baseFare = category?.baseFare ?? AppConstants.pricingBaseFare;
        final perKm = category?.perKmPrice ?? AppConstants.pricingPerKm;
        final perMin = category?.perMinutePrice ?? AppConstants.pricingPerMin;
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

  Future<List<VehicleCategory>> fetchVehicleCategories() async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'vehicle_categories',
      onlineFetch: () async {
        final response = await _client
            .from('vehicle_categories')
            .select()
            .order('created_at', ascending: true);
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    return rows.map((e) => VehicleCategory.fromMap(e)).toList();
  }
}

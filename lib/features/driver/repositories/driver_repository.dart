import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/trip_passenger.dart';
import '../../../core/models/vehicle_category.dart';
import '../../../core/services/local_database.dart';
import '../../../core/utils/cache_helper.dart';
import '../models/trip_model.dart';

class DriverRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>> fetchDriverProfile(String userId) async {
    return CacheHelper.fetchSingleWithCache(
      table: 'drivers',
      id: userId,
      onlineFetch: () async {
        final response = await _client
            .from('drivers')
            .select()
            .eq('id', userId)
            .maybeSingle();
        return response;
      },
    ).then((v) {
      if (v != null) return v;
      throw Exception('Driver profile not found');
    });
  }

  Future<void> updateAvailability(String userId, bool isAvailable) async {
    await CacheHelper.writeWithSync(
      table: 'drivers',
      id: userId,
      data: {'id': userId, 'is_available': isAvailable ? 1 : 0},
      onlineWrite: () => _client
          .from('drivers')
          .update({'is_available': isAvailable})
          .eq('id', userId),
    );
  }

  Future<void> updateLocation(String userId, double lat, double lng) async {
    if (CacheHelper.isOnline) {
      try {
        await _client.rpc('update_driver_location', params: {
          'p_driver_id': userId,
          'p_lat': lat,
          'p_lng': lng,
        });
      } catch (_) {}
    }
  }

  Future<Trip> createTrip({
    required String driverId,
    required double startLat,
    required double startLng,
  }) async {
    final data = {
      'driver_id': driverId,
      'start_lat': startLat,
      'start_lng': startLng,
      'status': 'active',
    };
    if (CacheHelper.isOnline) {
      try {
        final response = await _client.from('trips').insert(data).select().single();
        return Trip.fromMap(response);
      } catch (_) {
        final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
        await LocalDatabase.insert('trips', {...data, 'id': tempId});
        await LocalDatabase.addToSyncQueue('trips', 'insert', tempId, data);
        return Trip.fromMap({...data, 'id': tempId, 'created_at': DateTime.now().toIso8601String()});
      }
    }
    final tempId = 'local_${DateTime.now().millisecondsSinceEpoch}';
    await LocalDatabase.insert('trips', {...data, 'id': tempId});
    await LocalDatabase.addToSyncQueue('trips', 'insert', tempId, data);
    return Trip.fromMap({...data, 'id': tempId, 'created_at': DateTime.now().toIso8601String()});
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
    final updates = {
      'end_lat': endLat,
      'end_lng': endLng,
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'fare': fare,
      'driver_cut': driverCut,
      'status': 'completed',
      'completed_at': DateTime.now().toIso8601String(),
    };
    if (CacheHelper.isOnline) {
      try {
        final response = await _client.from('trips').update(updates).eq('id', tripId).select().single();
        await LocalDatabase.insert('trips', updates);
        return Trip.fromMap(response);
      } catch (_) {
        await LocalDatabase.insert('trips', {...updates, 'id': tripId});
        await LocalDatabase.addToSyncQueue('trips', 'update', tripId, updates);
      }
    } else {
      await LocalDatabase.insert('trips', {...updates, 'id': tripId});
      await LocalDatabase.addToSyncQueue('trips', 'update', tripId, updates);
    }
    final cached = await LocalDatabase.get('trips', tripId);
    return Trip.fromMap(cached ?? updates);
  }

  Future<List<Trip>> fetchTripHistory(String driverId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'trips',
      onlineFetch: () async {
        final response = await _client
            .from('trips')
            .select()
            .eq('driver_id', driverId)
            .order('created_at', ascending: false)
            .limit(50);
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    return rows.map((e) => Trip.fromMap(e)).toList();
  }

  Future<Map<String, dynamic>> fetchEarnings(String driverId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'trips',
      cacheKey: 'earnings_$driverId',
      onlineFetch: () async {
        final response = await _client
            .from('trips')
            .select('fare, driver_cut, created_at')
            .eq('driver_id', driverId)
            .eq('status', 'completed');
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    double totalFare = 0;
    double totalCut = 0;
    for (final t in rows) {
      totalFare += (t['fare'] as num?)?.toDouble() ?? 0;
      totalCut += (t['driver_cut'] as num?)?.toDouble() ?? 0;
    }
    return {'total_fare': totalFare, 'total_cut': totalCut, 'count': rows.length};
  }

  Future<List<TripPassenger>> fetchTripPassengers(String tripId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'trip_passengers',
      onlineFetch: () async {
        final response = await _client
            .from('trip_passengers')
            .select('*, profiles!inner(full_name, phone, rating)')
            .eq('trip_id', tripId)
            .order('created_at', ascending: true);
        return (response as List<dynamic>).map((e) {
          final map = e as Map<String, dynamic>;
          final profile = map['profiles'] as Map<String, dynamic>?;
          map['passenger_name'] = profile?['full_name'] as String?;
          map['passenger_phone'] = profile?['phone'] as String?;
          return map;
        }).toList();
      },
    );
    return rows.map((e) => TripPassenger.fromMap(e)).toList();
  }

  Future<String> generateShareCode(String tripId) async {
    final code = List.generate(6, (_) => '0123456789'[DateTime.now().microsecondsSinceEpoch % 10]).join();
    if (CacheHelper.isOnline) {
      try {
        await _client.from('trips').update({'share_code': code}).eq('id', tripId);
      } catch (_) {}
    }
    await LocalDatabase.insert('trips', {'id': tripId, 'share_code': code});
    return code;
  }

  Future<void> updatePassengerStatus(String tripPassengerId, String status) async {
    await CacheHelper.writeWithSync(
      table: 'trip_passengers',
      id: tripPassengerId,
      data: {'id': tripPassengerId, 'status': status},
      onlineWrite: () => _client
          .from('trip_passengers')
          .update({'status': status})
          .eq('id', tripPassengerId),
    );
  }

  Future<List<Trip>> fetchScheduledTrips(String driverId) async {
    final rows = await CacheHelper.fetchWithCache(
      table: 'trips',
      onlineFetch: () async {
        final response = await _client
            .from('trips')
            .select()
            .eq('driver_id', driverId)
            .eq('trip_type', 'scheduled')
            .eq('status', 'scheduled')
            .order('scheduled_at', ascending: true);
        return (response as List<dynamic>).cast<Map<String, dynamic>>();
      },
    );
    return rows.map((e) => Trip.fromMap(e)).toList();
  }

  Future<void> acceptScheduledTrip(String tripId) async {
    if (CacheHelper.isOnline) {
      try {
        await _client.from('trips').update({'status': 'active'}).eq('id', tripId);
      } catch (_) {
        await LocalDatabase.addToSyncQueue('trips', 'update', tripId, {'status': 'active'});
      }
    }
    await LocalDatabase.insert('trips', {'id': tripId, 'status': 'active'});
  }

  Future<Trip> fetchTripById(String tripId) async {
    final data = await CacheHelper.fetchSingleWithCache(
      table: 'trips',
      id: tripId,
      onlineFetch: () async {
        final response = await _client.from('trips').select().eq('id', tripId).single();
        return response as Map<String, dynamic>?;
      },
    );
    if (data != null) return Trip.fromMap(data);
    throw Exception('Trip not found');
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

  double calculateFare(double distanceKm, double durationMin, {double waitTimeMin = 0, VehicleCategory? category, bool passengerDiscount = false}) {
    final baseFare = category?.baseFare ?? AppConstants.pricingBaseFare;
    final perKm = category?.perKmPrice ?? AppConstants.pricingPerKm;
    final perMin = category?.perMinutePrice ?? AppConstants.pricingPerMin;
    final waitFarePerMin = category?.perWaitMinute ?? AppConstants.waitingFarePerMin;
    final fare = baseFare + (distanceKm * perKm) + (durationMin * perMin) + (waitTimeMin * waitFarePerMin);
    if (passengerDiscount) return fare * 0.85;
    return fare;
  }

  double calculateDriverCut(double fare, {bool premiumDriver = false}) {
    final commission = premiumDriver ? 0.10 : AppConstants.appCommissionRate;
    return fare * (1 - commission);
  }
}

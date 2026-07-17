import '../models/ride_request.dart';

class PassengerState {
  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> nearbyDrivers;
  final RideRequest? activeRequest;
  final List<RideRequest> rideHistory;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  final double? estimatedFare;
  final double? estimatedDistance;
  final double? estimatedDuration;

  const PassengerState({
    this.isLoading = false,
    this.error,
    this.nearbyDrivers = const [],
    this.activeRequest,
    this.rideHistory = const [],
    this.pickupLat = 0,
    this.pickupLng = 0,
    this.pickupAddress = '',
    this.destLat,
    this.destLng,
    this.destAddress,
    this.estimatedFare,
    this.estimatedDistance,
    this.estimatedDuration,
  });

  PassengerState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? nearbyDrivers,
    RideRequest? activeRequest,
    List<RideRequest>? rideHistory,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? destLat,
    double? destLng,
    String? destAddress,
    double? estimatedFare,
    double? estimatedDistance,
    double? estimatedDuration,
    bool clearError = false,
  }) {
    return PassengerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      nearbyDrivers: nearbyDrivers ?? this.nearbyDrivers,
      activeRequest: activeRequest ?? this.activeRequest,
      rideHistory: rideHistory ?? this.rideHistory,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      destAddress: destAddress ?? this.destAddress,
      estimatedFare: estimatedFare ?? this.estimatedFare,
      estimatedDistance: estimatedDistance ?? this.estimatedDistance,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
    );
  }
}

import '../../../core/models/trip_passenger.dart';
import '../../auth/models/user_model.dart';
import '../models/trip_model.dart';

class DriverState {
  final bool isLoading;
  final String? error;
  final DriverInfo? driverInfo;
  final bool isAvailable;
  final Trip? currentTrip;
  final List<Trip> tripHistory;
  final Map<String, dynamic>? earnings;
  final List<List<double>> routePoints;
  final double distanceKm;
  final double durationMin;
  final double waitTimeMin;
  final double currentFare;
  final double currentLat;
  final double currentLng;
  final bool isWaiting;
  final List<TripPassenger> tripPassengers;
  final String? shareCode;

  const DriverState({
    this.isLoading = false,
    this.error,
    this.driverInfo,
    this.isAvailable = false,
    this.currentTrip,
    this.tripHistory = const [],
    this.earnings,
    this.routePoints = const [],
    this.distanceKm = 0,
    this.durationMin = 0,
    this.waitTimeMin = 0,
    this.currentFare = 0,
    this.currentLat = 0,
    this.currentLng = 0,
    this.isWaiting = false,
    this.tripPassengers = const [],
    this.shareCode,
  });

  DriverState copyWith({
    bool? isLoading,
    String? error,
    DriverInfo? driverInfo,
    bool? isAvailable,
    Trip? currentTrip,
    List<Trip>? tripHistory,
    Map<String, dynamic>? earnings,
    List<List<double>>? routePoints,
    double? distanceKm,
    double? durationMin,
    double? waitTimeMin,
    double? currentFare,
    double? currentLat,
    double? currentLng,
    bool? isWaiting,
    List<TripPassenger>? tripPassengers,
    String? shareCode,
    bool clearError = false,
  }) {
    return DriverState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      driverInfo: driverInfo ?? this.driverInfo,
      isAvailable: isAvailable ?? this.isAvailable,
      currentTrip: currentTrip ?? this.currentTrip,
      tripHistory: tripHistory ?? this.tripHistory,
      earnings: earnings ?? this.earnings,
      routePoints: routePoints ?? this.routePoints,
      distanceKm: distanceKm ?? this.distanceKm,
      durationMin: durationMin ?? this.durationMin,
      waitTimeMin: waitTimeMin ?? this.waitTimeMin,
      currentFare: currentFare ?? this.currentFare,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      isWaiting: isWaiting ?? this.isWaiting,
      tripPassengers: tripPassengers ?? this.tripPassengers,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}

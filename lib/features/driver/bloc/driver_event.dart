
abstract class DriverEvent {}

class LoadDriverProfile extends DriverEvent {}

class ToggleAvailability extends DriverEvent {
  final bool isAvailable;
  ToggleAvailability({required this.isAvailable});
}

class UpdateDriverLocation extends DriverEvent {
  final double lat;
  final double lng;
  UpdateDriverLocation({required this.lat, required this.lng});
}

class StartTrip extends DriverEvent {
  final double startLat;
  final double startLng;
  StartTrip({required this.startLat, required this.startLng});
}

class EndTrip extends DriverEvent {
  final String tripId;
  final double endLat;
  final double endLng;
  final double distanceKm;
  final double durationMin;
  final double waitTimeMin;
  EndTrip({
    required this.tripId,
    required this.endLat,
    required this.endLng,
    required this.distanceKm,
    required this.durationMin,
    this.waitTimeMin = 0,
  });
}

class ToggleWaitTime extends DriverEvent {
  final bool isWaiting;
  ToggleWaitTime({required this.isWaiting});
}

class CancelTrip extends DriverEvent {
  final String tripId;
  CancelTrip(this.tripId);
}

class UpdateRoute extends DriverEvent {
  final List<List<double>> routePoints;
  final double distanceKm;
  final double durationMin;
  UpdateRoute({
    required this.routePoints,
    required this.distanceKm,
    required this.durationMin,
  });
}

class FetchTripHistory extends DriverEvent {}

class FetchEarnings extends DriverEvent {}

class LoadTripPassengers extends DriverEvent {
  final String tripId;
  LoadTripPassengers(this.tripId);
}

class GenerateShareCode extends DriverEvent {
  final String tripId;
  GenerateShareCode(this.tripId);
}

class UpdatePassengerStatus extends DriverEvent {
  final String tripPassengerId;
  final String status;
  UpdatePassengerStatus({required this.tripPassengerId, required this.status});
}

class FetchScheduledTrips extends DriverEvent {}

class AcceptScheduledTrip extends DriverEvent {
  final String tripId;
  AcceptScheduledTrip(this.tripId);
}

class UpdateDriverProfile extends DriverEvent {
  final String? driverType;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  UpdateDriverProfile({
    this.driverType,
    this.carModel,
    this.carPlate,
    this.carColor,
  });
}


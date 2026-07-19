abstract class PassengerEvent {}

class LoadNearbyDrivers extends PassengerEvent {
  final double lat;
  final double lng;
  LoadNearbyDrivers({required this.lat, required this.lng});
}

class RequestRide extends PassengerEvent {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  RequestRide({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.destLat,
    this.destLng,
    this.destAddress,
  });
}

class EstimateFare extends PassengerEvent {
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  EstimateFare({
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
  });
}

class CancelRide extends PassengerEvent {
  final String requestId;
  CancelRide(this.requestId);
}

class FetchActiveRequest extends PassengerEvent {}

class FetchRideHistory extends PassengerEvent {}

class RateDriver extends PassengerEvent {
  final String requestId;
  final double rating;
  final String? review;
  RateDriver({
    required this.requestId,
    required this.rating,
    this.review,
  });
}

class UpdatePickupLocation extends PassengerEvent {
  final double lat;
  final double lng;
  final String address;
  UpdatePickupLocation({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

class ScheduleRide extends PassengerEvent {
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  final DateTime scheduledAt;
  ScheduleRide({
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.destLat,
    this.destLng,
    this.destAddress,
    required this.scheduledAt,
  });
}

class FetchMyScheduledTrips extends PassengerEvent {}

class CancelScheduledTrip extends PassengerEvent {
  final String tripId;
  CancelScheduledTrip(this.tripId);
}

class JoinSharedRide extends PassengerEvent {
  final String shareCode;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  JoinSharedRide({
    required this.shareCode,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.destLat,
    this.destLng,
    this.destAddress,
  });
}

class UpdateDestination extends PassengerEvent {
  final double lat;
  final double lng;
  final String address;
  UpdateDestination({
    required this.lat,
    required this.lng,
    required this.address,
  });
}

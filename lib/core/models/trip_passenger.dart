class TripPassenger {
  final String id;
  final String tripId;
  final String passengerId;
  final String? passengerName;
  final String? passengerPhone;
  final double? passengerRating;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffAddress;
  final String status;
  final double? fare;
  final DateTime createdAt;

  TripPassenger({
    required this.id,
    required this.tripId,
    required this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.passengerRating,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffAddress,
    this.status = 'pending',
    this.fare,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isPickedUp => status == 'picked_up';
  bool get isDroppedOff => status == 'dropped_off';
  bool get isCancelled => status == 'cancelled';

  factory TripPassenger.fromMap(Map<String, dynamic> map) {
    return TripPassenger(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      passengerId: map['passenger_id'] as String,
      passengerName: map['passenger_name'] as String?,
      passengerPhone: map['passenger_phone'] as String?,
      passengerRating: (map['passenger_rating'] as num?)?.toDouble(),
      pickupLat: (map['pickup_lat'] as num).toDouble(),
      pickupLng: (map['pickup_lng'] as num).toDouble(),
      pickupAddress: map['pickup_address'] as String? ?? '',
      dropoffLat: (map['dropoff_lat'] as num?)?.toDouble(),
      dropoffLng: (map['dropoff_lng'] as num?)?.toDouble(),
      dropoffAddress: map['dropoff_address'] as String?,
      status: map['status'] as String? ?? 'pending',
      fare: (map['fare'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

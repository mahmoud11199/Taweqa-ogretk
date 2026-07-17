class RideRequest {
  final String id;
  final String passengerId;
  final String? driverId;
  final double pickupLat;
  final double pickupLng;
  final String pickupAddress;
  final double? destLat;
  final double? destLng;
  final String? destAddress;
  final String status;
  final double? estimatedFare;
  final double? estimatedDistance;
  final double? estimatedDuration;
  final String? driverName;
  final String? driverPhone;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  final double? driverLat;
  final double? driverLng;
  final double? driverRating;
  final DateTime createdAt;

  RideRequest({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupAddress,
    this.destLat,
    this.destLng,
    this.destAddress,
    this.status = 'pending',
    this.estimatedFare,
    this.estimatedDistance,
    this.estimatedDuration,
    this.driverName,
    this.driverPhone,
    this.carModel,
    this.carPlate,
    this.carColor,
    this.driverLat,
    this.driverLng,
    this.driverRating,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  factory RideRequest.fromMap(Map<String, dynamic> map) {
    return RideRequest(
      id: map['id'] as String,
      passengerId: map['passenger_id'] as String,
      driverId: map['driver_id'] as String?,
      pickupLat: (map['pickup_lat'] as num).toDouble(),
      pickupLng: (map['pickup_lng'] as num).toDouble(),
      pickupAddress: map['pickup_address'] as String? ?? '',
      destLat: (map['dest_lat'] as num?)?.toDouble(),
      destLng: (map['dest_lng'] as num?)?.toDouble(),
      destAddress: map['dest_address'] as String?,
      status: map['status'] as String? ?? 'pending',
      estimatedFare: (map['estimated_fare'] as num?)?.toDouble(),
      estimatedDistance: (map['estimated_distance'] as num?)?.toDouble(),
      estimatedDuration: (map['estimated_duration'] as num?)?.toDouble(),
      driverName: map['driver_name'] as String?,
      driverPhone: map['driver_phone'] as String?,
      carModel: map['car_model'] as String?,
      carPlate: map['car_plate'] as String?,
      carColor: map['car_color'] as String?,
      driverLat: (map['driver_lat'] as num?)?.toDouble(),
      driverLng: (map['driver_lng'] as num?)?.toDouble(),
      driverRating: (map['driver_rating'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

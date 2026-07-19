class Trip {
  final String id;
  final String driverId;
  final String? passengerId;
  final double startLat;
  final double startLng;
  final double? endLat;
  final double? endLng;
  final double? distanceKm;
  final double? durationMin;
  final double? fare;
  final double? driverCut;
  final String? passengerName;
  final String? passengerPhone;
  final double? passengerRating;
  final String status;
  final String tripType;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? completedAt;

  Trip({
    required this.id,
    required this.driverId,
    this.passengerId,
    required this.startLat,
    required this.startLng,
    this.endLat,
    this.endLng,
    this.distanceKm,
    this.durationMin,
    this.fare,
    this.driverCut,
    this.passengerName,
    this.passengerPhone,
    this.passengerRating,
    this.status = 'active',
    this.tripType = 'instant',
    this.scheduledAt,
    required this.createdAt,
    this.completedAt,
  });

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isScheduled => tripType == 'scheduled';
  bool get isUpcoming => isScheduled && scheduledAt != null && scheduledAt!.isAfter(DateTime.now());

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      driverId: map['driver_id'] as String,
      passengerId: map['passenger_id'] as String?,
      startLat: (map['start_lat'] as num?)?.toDouble() ?? 0,
      startLng: (map['start_lng'] as num?)?.toDouble() ?? 0,
      endLat: (map['end_lat'] as num?)?.toDouble(),
      endLng: (map['end_lng'] as num?)?.toDouble(),
      distanceKm: (map['distance_km'] as num?)?.toDouble(),
      durationMin: (map['duration_min'] as num?)?.toDouble(),
      fare: (map['fare'] as num?)?.toDouble(),
      driverCut: (map['driver_cut'] as num?)?.toDouble(),
      passengerName: map['passenger_name'] as String?,
      passengerPhone: map['passenger_phone'] as String?,
      passengerRating: (map['passenger_rating'] as num?)?.toDouble(),
      status: map['status'] as String? ?? 'active',
      tripType: map['trip_type'] as String? ?? 'instant',
      scheduledAt: map['scheduled_at'] != null
          ? DateTime.parse(map['scheduled_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'passenger_id': passengerId,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'distance_km': distanceKm,
      'duration_min': durationMin,
      'fare': fare,
      'driver_cut': driverCut,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'passenger_rating': passengerRating,
      'status': status,
      'trip_type': tripType,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }
}

enum TripStatus {
  active,
  completed,
  cancelled,
  scheduled;

  String get apiValue => name;

  static TripStatus fromApi(String value) {
    return TripStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TripStatus.active,
    );
  }
}

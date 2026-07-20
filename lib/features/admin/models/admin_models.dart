import '../../../core/utils/helpers.dart';

class AdminStats {
  final int totalDrivers;
  final int availableDrivers;
  final int totalPassengers;
  final int activeTrips;
  final int completedTrips;
  final int pendingApplications;
  final double totalRevenue;

  AdminStats({
    required this.totalDrivers,
    required this.availableDrivers,
    required this.totalPassengers,
    required this.activeTrips,
    required this.completedTrips,
    required this.pendingApplications,
    required this.totalRevenue,
  });

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalDrivers: (map['total_drivers'] as num?)?.toInt() ?? 0,
      availableDrivers: (map['available_drivers'] as num?)?.toInt() ?? 0,
      totalPassengers: (map['total_passengers'] as num?)?.toInt() ?? 0,
      activeTrips: (map['active_trips'] as num?)?.toInt() ?? 0,
      completedTrips: (map['completed_trips'] as num?)?.toInt() ?? 0,
      pendingApplications: (map['pending_applications'] as num?)?.toInt() ?? 0,
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_drivers': totalDrivers,
      'available_drivers': availableDrivers,
      'total_passengers': totalPassengers,
      'active_trips': activeTrips,
      'completed_trips': completedTrips,
      'pending_applications': pendingApplications,
      'total_revenue': totalRevenue,
    };
  }
}

class AdminDriver {
  final String id;
  final String fullName;
  final String? phone;
  final bool isAvailable;
  final bool banned;
  final String? driverType;
  final String? carModel;
  final String? carPlate;
  final double? rating;

  AdminDriver({
    required this.id,
    required this.fullName,
    this.phone,
    required this.isAvailable,
    this.banned = false,
    this.driverType,
    this.carModel,
    this.carPlate,
    this.rating,
  });

  factory AdminDriver.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>? ?? {};
    return AdminDriver(
      id: map['id'] as String,
      fullName: profile['full_name'] as String? ?? '',
      phone: profile['phone'] as String?,
      isAvailable: boolFromDynamic(map['is_available']),
      banned: boolFromDynamic(profile['banned']),
      driverType: map['driver_type'] as String?,
      carModel: map['car_model'] as String?,
      carPlate: map['car_plate'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'is_available': isAvailable,
      'banned': banned,
      'driver_type': driverType,
      'car_model': carModel,
      'car_plate': carPlate,
      'rating': rating,
    };
  }
}

class DriverApplication {
  final String userId;
  final String fullName;
  final String? phone;
  final String status;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  DriverApplication({
    required this.userId,
    required this.fullName,
    this.phone,
    required this.status,
    required this.payload,
    required this.createdAt,
  });

  factory DriverApplication.fromMap(Map<String, dynamic> map) {
    return DriverApplication(
      userId: map['user_id'] as String,
      fullName: map['full_name'] as String? ?? '',
      phone: map['phone'] as String?,
      status: map['status'] as String? ?? 'pending',
      payload: map['payload'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'status': status,
      'payload': payload,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

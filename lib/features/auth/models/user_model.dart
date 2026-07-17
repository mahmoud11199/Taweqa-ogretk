import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final int? rating;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.email,
    this.avatarUrl,
    this.rating,
    this.metadata,
  });

  bool get isDriver => role == 'driver';
  bool get isPassenger => role == 'passenger';
  bool get isAdmin => role == 'admin';

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String? ?? '',
      role: map['role'] as String? ?? 'passenger',
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      rating: map['rating'] as int?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  factory UserProfile.fromSupabaseUser(User user) {
    final meta = user.userMetadata;
    return UserProfile(
      id: user.id,
      fullName: meta?['full_name'] as String? ?? user.email ?? '',
      role: meta?['role'] as String? ?? 'passenger',
      phone: meta?['phone'] as String?,
      email: user.email,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}

class DriverInfo {
  final String id;
  final bool isAvailable;
  final String? driverType;
  final String? carModel;
  final String? carPlate;
  final String? carColor;
  final double? currentLat;
  final double? currentLng;

  DriverInfo({
    required this.id,
    required this.isAvailable,
    this.driverType,
    this.carModel,
    this.carPlate,
    this.carColor,
    this.currentLat,
    this.currentLng,
  });

  factory DriverInfo.fromMap(Map<String, dynamic> map) {
    return DriverInfo(
      id: map['id'] as String,
      isAvailable: map['is_available'] as bool? ?? false,
      driverType: map['driver_type'] as String?,
      carModel: map['car_model'] as String?,
      carPlate: map['car_plate'] as String?,
      carColor: map['car_color'] as String?,
      currentLat: (map['current_lat'] as num?)?.toDouble(),
      currentLng: (map['current_lng'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'is_available': isAvailable,
      'driver_type': driverType,
      'car_model': carModel,
      'car_plate': carPlate,
      'car_color': carColor,
    };
  }
}

class DriverApplication {
  final String userId;
  final String status;
  final Map<String, dynamic> payload;

  DriverApplication({
    required this.userId,
    required this.status,
    required this.payload,
  });

  factory DriverApplication.fromMap(Map<String, dynamic> map) {
    return DriverApplication(
      userId: map['user_id'] as String,
      status: map['status'] as String? ?? 'pending',
      payload: map['payload'] as Map<String, dynamic>? ?? {},
    );
  }
}

enum DriverType { private, tukTuk, motorcycle }

extension DriverTypeExtension on DriverType {
  String get label {
    switch (this) {
      case DriverType.private:
        return 'ملاكي';
      case DriverType.tukTuk:
        return 'توك توك';
      case DriverType.motorcycle:
        return 'موتوسيكل';
    }
  }

  String get apiValue {
    switch (this) {
      case DriverType.private:
        return 'private';
      case DriverType.tukTuk:
        return 'tuk-tuk';
      case DriverType.motorcycle:
        return 'motorcycle';
    }
  }

  static DriverType fromApi(String value) {
    switch (value) {
      case 'private':
        return DriverType.private;
      case 'tuk-tuk':
        return DriverType.tukTuk;
      case 'motorcycle':
        return DriverType.motorcycle;
      default:
        return DriverType.private;
    }
  }
}

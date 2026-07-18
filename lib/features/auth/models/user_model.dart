import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String role;
  final String? phone;
  final String? email;
  final String? avatarUrl;
  final double? rating;
  final bool banned;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.role,
    this.phone,
    this.email,
    this.avatarUrl,
    this.rating,
    this.banned = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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
      rating: (map['rating'] as num?)?.toDouble(),
      banned: map['banned'] as bool? ?? false,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
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
      banned: false,
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
      'rating': rating,
      'banned': banned,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
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
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverInfo({
    required this.id,
    required this.isAvailable,
    this.driverType,
    this.carModel,
    this.carPlate,
    this.carColor,
    this.currentLat,
    this.currentLng,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

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
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now(),
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
      'current_lat': currentLat,
      'current_lng': currentLng,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
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

import '../utils/helpers.dart';

class Subscription {
  final String id;
  final String userId;
  final String planType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final bool autoRenew;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    this.status = 'active',
    required this.startDate,
    required this.endDate,
    this.autoRenew = true,
    required this.createdAt,
  });

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(endDate);
  bool get isDriverPremium => planType == 'driver';
  bool get isPassengerDiscount => planType == 'passenger';

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      planType: map['plan_type'] as String,
      status: map['status'] as String? ?? 'active',
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: DateTime.parse(map['end_date'] as String),
      autoRenew: boolFromDynamic(map['auto_renew'], defaultValue: true),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
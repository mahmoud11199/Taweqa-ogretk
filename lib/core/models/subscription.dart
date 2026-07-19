class Subscription {
  final String id;
  final String userId;
  final String tierType;
  final double price;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.tierType,
    required this.price,
    required this.expiresAt,
    this.isActive = true,
    required this.createdAt,
  });

  bool get isDriverPremium => tierType == 'driver_premium';
  bool get isPassengerDiscount => tierType == 'passenger_discount';
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  factory Subscription.fromMap(Map<String, dynamic> map) {
    return Subscription(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      tierType: map['tier_type'] as String,
      price: (map['price'] as num).toDouble(),
      expiresAt: DateTime.parse(map['expires_at'] as String),
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

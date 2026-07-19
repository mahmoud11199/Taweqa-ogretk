class VehicleCategory {
  final String id;
  final String categoryName;
  final double baseFare;
  final double perKmPrice;
  final double perMinutePrice;
  final double perWaitMinute;

  const VehicleCategory({
    required this.id,
    required this.categoryName,
    required this.baseFare,
    required this.perKmPrice,
    required this.perMinutePrice,
    required this.perWaitMinute,
  });

  factory VehicleCategory.fromMap(Map<String, dynamic> map) {
    return VehicleCategory(
      id: map['id'] as String,
      categoryName: map['category_name'] as String? ?? '',
      baseFare: (map['base_fare'] as num?)?.toDouble() ?? 5.0,
      perKmPrice: (map['per_km_price'] as num?)?.toDouble() ?? 3.5,
      perMinutePrice: (map['per_minute_price'] as num?)?.toDouble() ?? 0.5,
      perWaitMinute: (map['per_wait_minute'] as num?)?.toDouble() ?? 0.25,
    );
  }
}

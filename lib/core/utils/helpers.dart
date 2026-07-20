import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

bool boolFromDynamic(dynamic value, {bool defaultValue = false}) {
  if (value == null) return defaultValue;
  if (value is bool) return value;
  if (value is int) return value != 0;
  return defaultValue;
}

bool get isWeb => kIsWeb;

String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(2)} ج';
}

String _pluralAr(int count, String singular, String dual, String plural) {
  if (count == 1) return 'منذ $count $singular';
  if (count == 2) return 'منذ $count $dual';
  return 'منذ $count $plural';
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return _pluralAr(diff.inSeconds, 'ثانية', 'ثانيتين', 'ثوانٍ');
  if (diff.inMinutes < 60) return _pluralAr(diff.inMinutes, 'دقيقة', 'دقيقتين', 'دقائق');
  if (diff.inHours < 24) return _pluralAr(diff.inHours, 'ساعة', 'ساعتين', 'ساعات');
  return _pluralAr(diff.inDays, 'يوم', 'يومين', 'أيام');
}

bool isMockedLocation(Position position) {
  try {
    return position.isMocked;
  } catch (_) {
    return false;
  }
}

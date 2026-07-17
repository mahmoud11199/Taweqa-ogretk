import 'dart:math';

String escapeHTML(String str) {
  return str
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

double clampNumber(double value, double min, double max, double fallback) {
  if (value.isNaN || value.isInfinite) return fallback;
  return value.clamp(min, max);
}

String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(2)} ج';
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return 'منذ ${diff.inSeconds} ثانية';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
  return 'منذ ${diff.inDays} يوم';
}

String generateJoinCode() {
  final rng = Random();
  return String.fromCharCodes(
    List.generate(6, (_) => rng.nextInt(10) + 48),
  );
}

String generateReferralCode() {
  final rng = Random();
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    List.generate(10, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

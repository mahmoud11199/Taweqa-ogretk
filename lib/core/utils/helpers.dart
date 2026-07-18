String formatCurrency(double amount) {
  return '${amount.toStringAsFixed(2)} ج';
}

String _plural(int count, String singular, String dual, String plural) {
  if (count == 1) return 'منذ $count $singular';
  if (count == 2) return 'منذ $count $dual';
  return 'منذ $count $plural';
}

String timeAgo(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inSeconds < 60) return _plural(diff.inSeconds, 'ثانية', 'ثانيتين', 'ثانية');
  if (diff.inMinutes < 60) return _plural(diff.inMinutes, 'دقيقة', 'دقيقتين', 'دقيقة');
  if (diff.inHours < 24) return _plural(diff.inHours, 'ساعة', 'ساعتين', 'ساعة');
  return _plural(diff.inDays, 'يوم', 'يومين', 'يوم');
}

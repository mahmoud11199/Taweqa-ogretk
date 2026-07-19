import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../driver/models/trip_model.dart';

class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final statusColor = trip.isCompleted
        ? AppTheme.success
        : trip.isCancelled
            ? AppTheme.error
            : AppTheme.warning;
    final statusText = trip.isCompleted
        ? 'مكتملة'
        : trip.isCancelled
            ? 'ملغاة'
            : 'نشطة';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('تفاصيل الرحلة')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.meterCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.meterBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (trip.distanceKm != null)
                _DetailRow(
                  icon: Icons.route_outlined,
                  label: 'المسافة',
                  value: '${trip.distanceKm!.toStringAsFixed(2)} كم',
                ),
              if (trip.durationMin != null)
                _DetailRow(
                  icon: Icons.timer_outlined,
                  label: 'المدة',
                  value: '${trip.durationMin!.toStringAsFixed(0)} دقيقة',
                ),
              if (trip.fare != null)
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'الأجرة',
                  value: formatCurrency(trip.fare!),
                  valueColor: AppTheme.fareNeon,
                ),
              if (trip.driverCut != null)
                _DetailRow(
                  icon: Icons.payments_outlined,
                  label: 'صافي السائق',
                  value: formatCurrency(trip.driverCut!),
                  valueColor: AppTheme.success,
                ),
              if (trip.passengerName != null && trip.passengerName!.isNotEmpty)
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'الراكب',
                  value: trip.passengerName!,
                ),
              if (trip.passengerPhone != null && trip.passengerPhone!.isNotEmpty)
                _DetailRow(
                  icon: Icons.phone_outlined,
                  label: 'الهاتف',
                  value: trip.passengerPhone!,
                ),
              if (trip.passengerRating != null)
                _DetailRow(
                  icon: Icons.star_rate_rounded,
                  label: 'تقييم الراكب',
                  value: List.generate(
                    trip.passengerRating!.round(),
                    (_) => '⭐',
                  ).join(),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: AppTheme.meterBorder),
              ),
              _DetailRow(
                icon: Icons.access_time,
                label: 'تاريخ الإنشاء',
                value: timeAgo(trip.createdAt),
              ),
              if (trip.completedAt != null)
                _DetailRow(
                  icon: Icons.check_circle_outline,
                  label: 'تاريخ الإكمال',
                  value: timeAgo(trip.completedAt!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.meterMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.meterMuted,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textDirection: value.contains('⭐') ? TextDirection.ltr : TextDirection.rtl,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

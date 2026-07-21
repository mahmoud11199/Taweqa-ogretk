import 'package:flutter/material.dart';
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
    final completed = trip.isCompleted;
    final cancelled = trip.isCancelled;
    final statusColor = completed ? const Color(0xFF00E5B8) : cancelled ? const Color(0xFFFF3B5C) : const Color(0xFFFFB020);
    final statusText = completed ? 'مكتملة' : cancelled ? 'ملغاة' : 'نشطة';

    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('تفاصيل الرحلة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1628),
            border: Border.all(color: const Color(0xFF1C2B45)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ),
              ),
              const SizedBox(height: 22),
              if (trip.distanceKm != null)
                _DetailRow(icon: Icons.route_outlined, label: 'المسافة', value: '${trip.distanceKm!.toStringAsFixed(2)} كم'),
              if (trip.durationMin != null)
                _DetailRow(icon: Icons.timer_outlined, label: 'المدة', value: '${trip.durationMin!.toStringAsFixed(0)} دقيقة'),
              if (trip.fare != null)
                _DetailRow(icon: Icons.account_balance_wallet_outlined, label: 'الأجرة', value: formatCurrency(trip.fare!), valueColor: const Color(0xFF00E5B8)),
              if (trip.driverCut != null)
                _DetailRow(icon: Icons.payments_outlined, label: 'صافي السائق', value: formatCurrency(trip.driverCut!), valueColor: const Color(0xFF00E5B8)),
              if (trip.passengerName != null && trip.passengerName!.isNotEmpty)
                _DetailRow(icon: Icons.person_outline, label: 'الراكب', value: trip.passengerName!),
              if (trip.passengerPhone != null && trip.passengerPhone!.isNotEmpty)
                _DetailRow(icon: Icons.phone_outlined, label: 'الهاتف', value: trip.passengerPhone!),
              if (trip.passengerRating != null)
                _DetailRow(
                  icon: Icons.star_rate_rounded, label: 'تقييم الراكب',
                  value: List.generate(trip.passengerRating!.round(), (_) => '⭐').join(),
                ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(color: Color(0xFF1C2B45)),
              ),
              _DetailRow(icon: Icons.access_time, label: 'تاريخ الإنشاء', value: timeAgo(trip.createdAt)),
              if (trip.completedAt != null)
                _DetailRow(icon: Icons.check_circle_outline, label: 'تاريخ الإكمال', value: timeAgo(trip.completedAt!)),
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

  const _DetailRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF526480)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(color: Color(0xFF526480), fontSize: 14)),
          Expanded(
            child: Text(
              value,
              textDirection: value.contains('⭐') ? TextDirection.ltr : TextDirection.rtl,
              style: TextStyle(color: valueColor ?? const Color(0xFFEDF2FC), fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

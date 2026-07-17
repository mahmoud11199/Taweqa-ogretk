import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../models/trip_model.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(FetchTripHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('سجل الرحلات')),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          if (state.tripHistory.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد رحلات بعد',
                style: TextStyle(color: AppTheme.meterMuted, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.tripHistory.length,
            itemBuilder: (context, index) {
              final trip = state.tripHistory[index];
              return _TripCard(trip: trip);
            },
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;

  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.meterCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              if (trip.fare != null)
                Text(
                  formatCurrency(trip.fare!),
                  style: const TextStyle(
                    color: AppTheme.fareNeon,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
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
          _DetailRow(
            icon: Icons.access_time,
            label: 'التاريخ',
            value: timeAgo(trip.createdAt),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.meterMuted),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.meterMuted,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

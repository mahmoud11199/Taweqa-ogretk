import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../trip/screens/trip_details_screen.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';

class ScheduledTripsScreen extends StatefulWidget {
  const ScheduledTripsScreen({super.key});

  @override
  State<ScheduledTripsScreen> createState() => _ScheduledTripsScreenState();
}

class _ScheduledTripsScreenState extends State<ScheduledTripsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(FetchScheduledTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('الرحلات المجدولة'),
        backgroundColor: AppTheme.meterCard,
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          final scheduled = state.tripHistory.where((t) => t.isScheduled && t.isUpcoming).toList();
          if (scheduled.isEmpty) {
            return const Center(
              child: Text('لا توجد رحلات مجدولة', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: scheduled.length,
            itemBuilder: (context, index) {
              final trip = scheduled[index];
              final timeStr = trip.scheduledAt != null
                  ? '${trip.scheduledAt!.hour.toString().padLeft(2, '0')}:${trip.scheduledAt!.minute.toString().padLeft(2, '0')} - ${trip.scheduledAt!.day}/${trip.scheduledAt!.month}'
                  : '';
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
                        const Icon(Icons.schedule, color: AppTheme.meterPrimary, size: 20),
                        const SizedBox(width: 8),
                        Text(timeStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.passengerName ?? 'راكب',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'من: ${trip.startLat.toStringAsFixed(4)}, ${trip.startLng.toStringAsFixed(4)}',
                      style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip)),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.meterCard,
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: AppTheme.meterMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('تفاصيل'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => context.read<DriverBloc>().add(AcceptScheduledTrip(trip.id)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('بدء الرحلة'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

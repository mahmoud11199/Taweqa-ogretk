import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';

class MyScheduledTripsScreen extends StatefulWidget {
  const MyScheduledTripsScreen({super.key});

  @override
  State<MyScheduledTripsScreen> createState() => _MyScheduledTripsScreenState();
}

class _MyScheduledTripsScreenState extends State<MyScheduledTripsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PassengerBloc>().add(FetchMyScheduledTrips());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('رحلاتي المجدولة'),
        backgroundColor: AppTheme.meterCard,
      ),
      body: BlocBuilder<PassengerBloc, PassengerState>(
        builder: (context, state) {
          if (state.scheduledTrips.isEmpty) {
            return const Center(
              child: Text('لا توجد رحلات مجدولة', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.scheduledTrips.length,
            itemBuilder: (context, index) {
              final trip = state.scheduledTrips[index];
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
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('مجدولة', style: TextStyle(color: AppTheme.accent, fontSize: 11)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(trip.pickupAddress, style: const TextStyle(color: Colors.white, fontSize: 13)),
                    if (trip.destAddress != null) ...[
                      const SizedBox(height: 4),
                      Text('→ ${trip.destAddress}', style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.read<PassengerBloc>().add(CancelScheduledTrip(trip.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.error.withValues(alpha: 0.2),
                          foregroundColor: AppTheme.error,
                          side: const BorderSide(color: AppTheme.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('إلغاء الحجز'),
                      ),
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

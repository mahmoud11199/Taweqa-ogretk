import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PassengerBloc>().add(FetchRideHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('سجل الرحلات')),
      body: BlocBuilder<PassengerBloc, PassengerState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          if (state.rideHistory.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد رحلات سابقة',
                style: TextStyle(color: AppTheme.meterMuted, fontSize: 16),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.rideHistory.length,
            itemBuilder: (context, index) {
              final ride = state.rideHistory[index];
              final statusColor = ride.isCompleted
                  ? AppTheme.success
                  : AppTheme.error;
              final statusText = ride.isCompleted ? 'مكتملة' : 'ملغاة';
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
                          child: Text(statusText,
                              style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        if (ride.estimatedFare != null)
                          Text(formatCurrency(ride.estimatedFare!),
                              style: const TextStyle(color: AppTheme.fareNeon, fontSize: 16, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(ride.pickupAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 14)),
                    if (ride.destAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('→ ${ride.destAddress}',
                            style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13)),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(timeAgo(ride.createdAt),
                          style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
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

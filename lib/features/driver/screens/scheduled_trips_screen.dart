import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('الرحلات المجدولة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          final scheduled = state.tripHistory.where((t) => t.isScheduled && t.isUpcoming).toList();
          if (scheduled.isEmpty) return const Center(child: Text('لا توجد رحلات مجدولة', style: TextStyle(color: Color(0xFF526480))));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: scheduled.length,
            itemBuilder: (context, index) {
              final trip = scheduled[index];
              final timeStr = trip.scheduledAt != null
                  ? '${trip.scheduledAt!.hour.toString().padLeft(2, '0')}:${trip.scheduledAt!.minute.toString().padLeft(2, '0')} - ${trip.scheduledAt!.day}/${trip.scheduledAt!.month}'
                  : '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1628),
                  border: Border.all(color: const Color(0xFF1C2B45)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.schedule, color: Color(0xFF0088CC), size: 20),
                        const SizedBox(width: 8),
                        Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(trip.passengerName ?? 'راكب', style: const TextStyle(fontSize: 14, color: Color(0xFFEDF2FC))),
                    const SizedBox(height: 4),
                    Text('من: ${trip.startLat.toStringAsFixed(4)}, ${trip.startLng.toStringAsFixed(4)}', style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip))),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F1628),
                                foregroundColor: const Color(0xFFEDF2FC),
                                side: const BorderSide(color: Color(0xFF1C2B45)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('تفاصيل', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 42,
                            child: ElevatedButton(
                              onPressed: () => context.read<DriverBloc>().add(AcceptScheduledTrip(trip.id)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00E5B8),
                                foregroundColor: const Color(0xFF080D18),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('بدء الرحلة', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
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

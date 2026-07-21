import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('رحلاتي المجدولة', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PassengerBloc, PassengerState>(
        builder: (context, state) {
          if (state.scheduledTrips.isEmpty) {
            return const Center(child: Text('لا توجد رحلات مجدولة', style: TextStyle(color: Color(0xFF526480))));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.scheduledTrips.length,
            itemBuilder: (context, index) {
              final trip = state.scheduledTrips[index];
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
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 136, 204, 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color.fromRGBO(0, 136, 204, 0.3)),
                          ),
                          child: const Text('مجدولة', style: TextStyle(color: Color(0xFF0088CC), fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 14, color: Color(0xFF00E5B8)),
                        const SizedBox(width: 6),
                        Text(trip.pickupAddress, style: const TextStyle(fontSize: 13, color: Color(0xFFEDF2FC))),
                      ],
                    ),
                    if (trip.destAddress != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.flag, size: 14, color: Color(0xFFFFB020)),
                          const SizedBox(width: 6),
                          Text('→ ${trip.destAddress}', style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity, height: 42,
                      child: ElevatedButton(
                        onPressed: () => context.read<PassengerBloc>().add(CancelScheduledTrip(trip.id)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(255, 59, 92, 0.1),
                          foregroundColor: const Color(0xFFFF3B5C),
                          side: const BorderSide(color: Color(0xFFFF3B5C)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('إلغاء الحجز', style: TextStyle(fontWeight: FontWeight.w700)),
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

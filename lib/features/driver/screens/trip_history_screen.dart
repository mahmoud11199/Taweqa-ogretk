import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../models/trip_model.dart';
import '../../trip/screens/trip_details_screen.dart';

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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('سجل الرحلات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          if (state.tripHistory.isEmpty) return const Center(child: Text('لا توجد رحلات بعد', style: TextStyle(color: Color(0xFF526480), fontSize: 16)));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.tripHistory.length,
            itemBuilder: (context, index) {
              final trip = state.tripHistory[index];
              return _TripCard(trip: trip, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailsScreen(trip: trip))));
            },
          );
        },
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback? onTap;
  const _TripCard({required this.trip, this.onTap});

  @override
  Widget build(BuildContext context) {
    final completed = trip.isCompleted;
    final cancelled = trip.isCancelled;
    final statusColor = completed ? const Color(0xFF00E5B8) : cancelled ? const Color(0xFFFF3B5C) : const Color(0xFFFFB020);
    final statusText = completed ? 'مكتملة' : cancelled ? 'ملغاة' : 'نشطة';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withAlpha(60)),
                  ),
                  child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                if (trip.fare != null)
                  Text(formatCurrency(trip.fare!), style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8))),
              ],
            ),
            const SizedBox(height: 10),
            if (trip.distanceKm != null) _DRow(icon: Icons.route_outlined, label: 'المسافة', value: '${trip.distanceKm!.toStringAsFixed(2)} كم'),
            if (trip.durationMin != null) _DRow(icon: Icons.timer_outlined, label: 'المدة', value: '${trip.durationMin!.toStringAsFixed(0)} دقيقة'),
            _DRow(icon: Icons.access_time, label: 'التاريخ', value: timeAgo(trip.createdAt)),
          ],
        ),
      ),
    );
  }
}

class _DRow extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _DRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF526480)),
          const SizedBox(width: 6),
          Text('$label: ', style: const TextStyle(color: Color(0xFF526480), fontSize: 13)),
          Text(value, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

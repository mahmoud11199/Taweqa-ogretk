import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';
import '../../rating/screens/rating_screen.dart';

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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('سجل الرحلات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<PassengerBloc, PassengerState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          }
          if (state.rideHistory.isEmpty) {
            return const Center(child: Text('لا توجد رحلات سابقة', style: TextStyle(color: Color(0xFF526480), fontSize: 16)));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.rideHistory.length,
            itemBuilder: (context, index) {
              final ride = state.rideHistory[index];
              final completed = ride.isCompleted;
              final statusColor = completed ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C);
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(25),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor.withAlpha(60)),
                          ),
                          child: Text(completed ? 'مكتملة' : 'ملغاة', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                        ),
                        const Spacer(),
                        if (ride.estimatedFare != null)
                          Text(formatCurrency(ride.estimatedFare!), style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.my_location, size: 14, color: Color(0xFF00E5B8)),
                        const SizedBox(width: 6),
                        Expanded(child: Text(ride.pickupAddress, style: const TextStyle(fontSize: 13, color: Color(0xFFEDF2FC)))),
                      ],
                    ),
                    if (ride.destAddress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.flag, size: 14, color: Color(0xFFFFB020)),
                            const SizedBox(width: 6),
                            Text('→ ${ride.destAddress}', style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(timeAgo(ride.createdAt), style: const TextStyle(fontSize: 11, color: Color(0xFF3A5070))),
                    ),
                    if (completed && ride.driverName != null && ride.rating == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SizedBox(
                          width: double.infinity, height: 38,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => RatingScreen(requestId: ride.id, driverName: ride.driverName!)),
                              );
                              if (result == true && context.mounted) showToast(context, 'تم إرسال التقييم بنجاح');
                            },
                            icon: const Icon(Icons.star_rate, size: 16),
                            label: const Text('تقييم', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromRGBO(255, 176, 32, 0.1),
                              foregroundColor: const Color(0xFFFFB020),
                              side: const BorderSide(color: Color.fromRGBO(255, 176, 32, 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                          ),
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

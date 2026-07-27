import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../passenger/models/ride_request.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import 'scheduled_trips_screen.dart';

class DriverDispatchScreen extends StatelessWidget {
  const DriverDispatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('طلبات الركاب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: const Color(0xFF00E5B8),
            labelColor: const Color(0xFF00E5B8),
            unselectedLabelColor: const Color(0xFF526480),
            tabs: const [
              Tab(icon: Icon(Icons.flash_on, size: 18), text: 'مباشر'),
              Tab(icon: Icon(Icons.calendar_month, size: 18), text: 'مجدول'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RideRequestsTab(),
            const ScheduledTripsScreen(),
          ],
        ),
      ),
    );
  }
}

class _RideRequestsTab extends StatefulWidget {
  @override
  State<_RideRequestsTab> createState() => _RideRequestsTabState();
}

class _RideRequestsTabState extends State<_RideRequestsTab> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(FetchRideRequests());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverBloc, DriverState>(
      builder: (context, state) {
        final requests = state.rideRequests;
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF1C2B45)),
                const SizedBox(height: 16),
                const Text('لا توجد طلبات حالياً', style: TextStyle(fontSize: 16, color: Color(0xFF526480))),
                const SizedBox(height: 8),
                Text(state.isAvailable ? 'بانتظار طلبات الركاب...' : 'فعّل التوفر لاستقبال الطلبات',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF3A5070))),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, i) => _RequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RideRequest request;
  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(request.createdAt);
    final timeStr = elapsed.inMinutes < 1
        ? 'منذ لحظات'
        : 'منذ ${elapsed.inMinutes} د';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF152038),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('👤', style: TextStyle(fontSize: 20))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(request.passengerId, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                    const SizedBox(height: 2),
                    Text(request.pickupAddress, style: const TextStyle(fontSize: 11, color: Color(0xFF526480))),
                  ],
                ),
              ),
              Text(timeStr, style: const TextStyle(fontSize: 10, color: Color(0xFF3A5070))),
            ],
          ),
          if (request.estimatedFare != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 14, color: Color(0xFFFFB020)),
                const SizedBox(width: 4),
                Text('${request.estimatedFare!.toStringAsFixed(0)} ج.م',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFB020), fontFamily: 'monospace')),
                if (request.estimatedDistance != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.route, size: 14, color: Color(0xFF8EA4C8)),
                  const SizedBox(width: 4),
                  Text('${request.estimatedDistance!.toStringAsFixed(1)} كم',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
                ],
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    context.read<DriverBloc>().add(AcceptRideRequest(request.id));
                    showToast(context, 'تم قبول الطلب', isError: false);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5B8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('قبول', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF080D18))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.read<DriverBloc>().add(RejectRideRequest(request.id)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 59, 92, 0.1),
                      border: Border.all(color: const Color.fromRGBO(255, 59, 92, 0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('رفض', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF3B5C))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
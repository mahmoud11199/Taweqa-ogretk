import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';

class RideTrackingScreen extends StatelessWidget {
  const RideTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PassengerBloc, PassengerState>(
      builder: (context, state) {
        final request = state.activeRequest;
        if (request == null) {
          return const Center(
            child: Text('لا توجد رحلة نشطة',
                style: TextStyle(color: AppTheme.meterMuted)),
          );
        }
        return Scaffold(
          backgroundColor: AppTheme.bgDeep,
          appBar: AppBar(
            title: Text(request.isPending ? 'جاري البحث عن سائق' : 'الرحلة الحالية'),
          ),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(request.pickupLat, request.pickupLng),
                  initialZoom: 14,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taweqa.ogretk',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(request.pickupLat, request.pickupLng),
                        width: 40, height: 40,
                        child: const Icon(Icons.location_on, color: AppTheme.success, size: 36),
                      ),
                      if (request.driverLat != null)
                        Marker(
                          point: LatLng(request.driverLat!, request.driverLng!),
                          width: 40, height: 40,
                          child: const Icon(Icons.local_taxi, color: AppTheme.meterPrimary, size: 32),
                        ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 24, left: 16, right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.meterCard,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (request.isPending) ...[
                        const SizedBox(
                          width: 24, height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.meterPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('جاري البحث عن سائق قريب...',
                            style: TextStyle(color: AppTheme.meterMuted)),
                      ],
                      if (request.isAccepted && request.driverName != null) ...[
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.meterPrimary,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(request.driverName!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      )),
                                  if (request.carModel != null)
                                    Text('${request.carModel} - ${request.carPlate}',
                                        style: const TextStyle(
                                          color: AppTheme.meterMuted,
                                          fontSize: 13,
                                        )),
                                ],
                              ),
                            ),
                            if (request.estimatedFare != null)
                              Text(formatCurrency(request.estimatedFare!),
                                  style: const TextStyle(
                                    color: AppTheme.fareNeon,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  )),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity, height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            context.read<PassengerBloc>().add(CancelRide(request.id));
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('إلغاء الرحلة',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

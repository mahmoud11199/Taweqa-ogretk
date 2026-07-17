import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final MapController _mapController = MapController();
  double _currentLat = 26.8206;
  double _currentLng = 30.8025;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      context.read<PassengerBloc>().add(UpdatePickupLocation(
        lat: _currentLat,
        lng: _currentLng,
        address: 'موقعي الحالي',
      ));
      context.read<PassengerBloc>().add(LoadNearbyDrivers(
        lat: _currentLat,
        lng: _currentLng,
      ));
      _mapController.move(LatLng(_currentLat, _currentLng), 14);
    } catch (_) {}
  }

  void _requestRide() {
    final state = context.read<PassengerBloc>().state;
    if (state.pickupLat == 0) {
      showToast(context, 'يرجى تحديد موقع الالتقاط', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(RequestRide(
      pickupLat: state.pickupLat,
      pickupLng: state.pickupLng,
      pickupAddress: state.pickupAddress,
      destLat: state.destLat,
      destLng: state.destLng,
      destAddress: state.destAddress,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 14,
              onTap: (tapPos, latlng) {
                context.read<PassengerBloc>().add(UpdatePickupLocation(
                  lat: latlng.latitude,
                  lng: latlng.longitude,
                  address: 'موقع محدد',
                ));
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.taweqa.ogretk',
              ),
              BlocBuilder<PassengerBloc, PassengerState>(
                builder: (context, state) {
                  return MarkerLayer(
                    markers: [
                      if (state.pickupLat != 0)
                        Marker(
                          point: LatLng(state.pickupLat, state.pickupLng),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: AppTheme.success, size: 36),
                        ),
                      if (state.destLat != null)
                        Marker(
                          point: LatLng(state.destLat!, state.destLng!),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: AppTheme.error, size: 36),
                        ),
                      ...state.nearbyDrivers.map((d) => Marker(
                        point: LatLng(
                          (d['current_lat'] as num).toDouble(),
                          (d['current_lng'] as num).toDouble(),
                        ),
                        width: 30,
                        height: 30,
                        child: const Icon(Icons.local_taxi, color: AppTheme.meterPrimary, size: 24),
                      )),
                    ],
                  );
                },
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.meterCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'موقع الالتقاط',
                      prefixIcon: Icon(Icons.my_location, color: AppTheme.success),
                      filled: true,
                      fillColor: AppTheme.bgDeep,
                    ),
                    enabled: false,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'الوجهة (اختياري)',
                      prefixIcon: Icon(Icons.flag, color: AppTheme.error),
                      filled: true,
                      fillColor: AppTheme.bgDeep,
                    ),
                    onTap: () {
                      // TODO: Open destination picker
                    },
                  ),
                  const SizedBox(height: 12),
                  BlocBuilder<PassengerBloc, PassengerState>(
                    builder: (context, state) {
                      return SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _requestRide,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('طلب رحلة', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

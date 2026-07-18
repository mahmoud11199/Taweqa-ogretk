import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import 'earnings_screen.dart';
import 'trip_history_screen.dart';

class DriverMeterScreen extends StatefulWidget {
  const DriverMeterScreen({super.key});

  @override
  State<DriverMeterScreen> createState() => _DriverMeterScreenState();
}

class _DriverMeterScreenState extends State<DriverMeterScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _gpsTimer;
  bool _tripActive = false;

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(LoadDriverProfile());
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) {
      if (!mounted) return;
      context.read<DriverBloc>().add(UpdateDriverLocation(
        lat: position.latitude,
        lng: position.longitude,
      ));
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    });
  }

  void _updateRoute() async {
    if (!mounted) return;
    final state = context.read<DriverBloc>().state;
    if (state.currentLat == 0 || state.currentLng == 0) return;
    if (!_tripActive) return;

    // Simulate route update with current position
    context.read<DriverBloc>().add(UpdateRoute(
      routePoints: [
        [state.currentLng, state.currentLat],
      ],
      distanceKm: state.distanceKm + 0.1,
      durationMin: state.durationMin + 0.1,
    ));
  }

  void _startTrip() {
    final state = context.read<DriverBloc>().state;
    if (state.currentLat == 0 || state.currentLng == 0) {
      showToast(context, 'لم يتم تحديد الموقع بعد', isError: true);
      return;
    }
    setState(() => _tripActive = true);
    context.read<DriverBloc>().add(StartTrip(
      startLat: state.currentLat,
      startLng: state.currentLng,
    ));
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateRoute());
  }

  void _endTrip() {
    _gpsTimer?.cancel();
    final state = context.read<DriverBloc>().state;
    if (state.currentTrip == null) return;
    context.read<DriverBloc>().add(EndTrip(
      tripId: state.currentTrip!.id,
      endLat: state.currentLat,
      endLng: state.currentLng,
      distanceKm: state.distanceKm,
      durationMin: state.durationMin,
    ));
    setState(() => _tripActive = false);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverBloc, DriverState>(
      listener: (context, state) {
        if (state.error != null) {
          showToast(context, state.error!, isError: true);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        drawer: Drawer(
          child: Container(
            color: AppTheme.bgDeep,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: AppTheme.meterCard),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.local_taxi_rounded, size: 48, color: AppTheme.meterPrimary),
                      const SizedBox(height: 8),
                      Text(
                        'توقع أجرتك',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      BlocBuilder<DriverBloc, DriverState>(
                        builder: (context, state) => Text(
                          state.driverInfo?.carModel ?? 'سائق',
                          style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map, color: AppTheme.meterPrimary),
                  title: const Text('الصفحة الرئيسية', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pop(context),
                ),
                ListTile(
                  leading: const Icon(Icons.history, color: AppTheme.meterPrimary),
                  title: const Text('سجل الرحلات', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.monetization_on, color: AppTheme.meterPrimary),
                  title: const Text('الأرباح', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.wallet, color: AppTheme.meterPrimary),
                  title: const Text('المحفظة', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: AppTheme.meterPrimary),
                  title: const Text('الدردشة', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                  },
                ),
                const Divider(color: AppTheme.meterCard),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppTheme.error),
                  title: const Text('تسجيل الخروج', style: TextStyle(color: AppTheme.error)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
                ),
              ],
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(26.8206, 30.8025),
                  initialZoom: 13,
                  onTap: (tapPos, latlng) {},
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.taweqa.ogretk',
                  ),
                  BlocBuilder<DriverBloc, DriverState>(
                    builder: (context, state) {
                      if (state.currentLat == 0) return const SizedBox();
                      return MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(state.currentLat, state.currentLng),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: state.isAvailable
                                    ? AppTheme.success
                                    : AppTheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.navigation,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  BlocBuilder<DriverBloc, DriverState>(
                    builder: (context, state) {
                      if (state.routePoints.isEmpty) return const SizedBox();
                      return PolylineLayer(
                        polylines: [
                          Polyline(
                            points: state.routePoints
                                .where((p) => p.length >= 2)
                                .map((p) => LatLng(p[1], p[0]))
                                .toList(),
                            color: AppTheme.meterPrimary,
                            strokeWidth: 4,
                          ),
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
                child: BlocBuilder<DriverBloc, DriverState>(
                  builder: (context, state) {
                    return Container(
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
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: state.isAvailable
                                      ? AppTheme.success
                                      : AppTheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.isAvailable ? 'متاح' : 'غير متاح',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${state.distanceKm.toStringAsFixed(1)} كم',
                                style: const TextStyle(
                                  color: AppTheme.meterMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          if (_tripActive) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _InfoChip(
                                  icon: Icons.timer_outlined,
                                  label:                               '${state.durationMin.isFinite ? state.durationMin.toStringAsFixed(0) : '0'} د',
                                ),
                                _InfoChip(
                                  icon: Icons.route_outlined,
                                  label: '${state.distanceKm.toStringAsFixed(2)} كم',
                                ),
                                _InfoChip(
                                  icon: Icons.monetization_on_outlined,
                                  label: '${state.currentFare.toStringAsFixed(0)} ج',
                                  valueColor: AppTheme.fareNeon,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                bottom: 32,
                left: 24,
                right: 24,
                child: BlocBuilder<DriverBloc, DriverState>(
                  builder: (context, state) {
                    return Row(
                      children: [
                        if (!_tripActive)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _startTrip(),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('بدء الرحلة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.success,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        if (_tripActive) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _endTrip,
                              icon: const Icon(Icons.stop),
                              label: const Text('إنهاء الرحلة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.error,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.meterCard,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () {
                              context.read<DriverBloc>().add(ToggleAvailability(
                                isAvailable: !state.isAvailable,
                              ));
                            },
                            icon: Icon(
                              state.isAvailable
                                  ? Icons.toggle_on
                                  : Icons.toggle_off_outlined,
                              color: state.isAvailable
                                  ? AppTheme.success
                                  : AppTheme.error,
                              size: 36,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.meterPrimary, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

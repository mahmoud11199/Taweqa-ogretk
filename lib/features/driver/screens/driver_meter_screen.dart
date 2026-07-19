import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../landing/screens/landing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../subscription/bloc/subscription_bloc.dart';
import '../../subscription/bloc/subscription_event.dart';
import '../../subscription/screens/subscription_plans_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import 'earnings_screen.dart';
import 'scheduled_trips_screen.dart';
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
      if (isMockedLocation(position)) {
        showToast(context, 'تحذير: تم اكتشاف موقع وهمي!', isError: true);
        return;
      }
      context.read<DriverBloc>().add(UpdateDriverLocation(
        lat: position.latitude,
        lng: position.longitude,
      ));
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    }, onError: (_) {
      if (mounted) showToast(context, 'تعذر الحصول على الموقع', isError: true);
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
    final s = context.read<DriverBloc>().state;
    if (s.currentLat == 0 || s.currentLng == 0) {
      showToast(context, 'لم يتم تحديد الموقع بعد', isError: true);
      return;
    }
    setState(() => _tripActive = true);
    context.read<DriverBloc>().add(StartTrip(
      startLat: s.currentLat,
      startLng: s.currentLng,
    ));
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateRoute());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<DriverBloc>();
      bloc.stream.firstWhere((st) => st.currentTrip != null).then((st) {
        if (st.currentTrip != null) {
          bloc.add(GenerateShareCode(st.currentTrip!.id));
          bloc.add(LoadTripPassengers(st.currentTrip!.id));
        }
      });
    });
  }

  void _endTrip() {
    _gpsTimer?.cancel();
    final s = context.read<DriverBloc>().state;
    if (s.currentTrip == null) return;
    context.read<DriverBloc>().add(EndTrip(
      tripId: s.currentTrip!.id,
      endLat: s.currentLat,
      endLng: s.currentLng,
      distanceKm: s.distanceKm,
      durationMin: s.durationMin,
      waitTimeMin: s.waitTimeMin,
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LandingScreen()),
            (route) => false,
          );
        }
      },
      child: BlocListener<DriverBloc, DriverState>(
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
                      const Text(
                        'توقع أجرتك',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState is AuthAuthenticated ? authState.profile.fullName : 'سائق',
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            BlocBuilder<DriverBloc, DriverState>(
                              builder: (context, state) => Text(
                                state.driverInfo?.carModel ?? '',
                                style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12),
                              ),
                            ),
                          ],
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
                  leading: const Icon(Icons.schedule, color: AppTheme.meterPrimary),
                  title: const Text('الرحلات المجدولة', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledTripsScreen()));
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
                  leading: const Icon(Icons.card_giftcard, color: AppTheme.meterPrimary),
                  title: const Text('الباقات', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<SubscriptionBloc>().add(LoadSubscription());
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()));
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
                ListTile(
                  leading: const Icon(Icons.settings, color: AppTheme.meterPrimary),
                  title: const Text('الإعدادات', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
                      final markers = <Marker>[];
                      if (state.currentLat != 0) {
                        markers.add(Marker(
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
                        ));
                      }
                      return Stack(
                        children: [
                          if (markers.isNotEmpty) MarkerLayer(markers: markers),
                          if (state.routePoints.isNotEmpty)
                            PolylineLayer(
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
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => context.read<DriverBloc>().add(
                                    ToggleWaitTime(isWaiting: !state.isWaiting),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: state.isWaiting ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.meterCard,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: state.isWaiting ? AppTheme.accent : AppTheme.meterMuted,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.hourglass_bottom,
                                          size: 16,
                                          color: state.isWaiting ? AppTheme.accent : AppTheme.meterMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'انتظار: ${state.waitTimeMin.toStringAsFixed(0)} د',
                                          style: TextStyle(
                                            color: state.isWaiting ? AppTheme.accent : AppTheme.meterMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    final s = context.read<DriverBloc>().state;
                                    if (s.currentTrip != null && s.shareCode == null) {
                                      context.read<DriverBloc>().add(GenerateShareCode(s.currentTrip!.id));
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: state.shareCode != null
                                          ? AppTheme.success.withValues(alpha: 0.2)
                                          : AppTheme.meterCard,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: state.shareCode != null ? AppTheme.success : AppTheme.meterMuted,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.share,
                                          size: 16,
                                          color: state.shareCode != null ? AppTheme.success : AppTheme.meterMuted,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          state.shareCode != null
                                              ? 'الكود: ${state.shareCode}'
                                              : 'مشاركة الرحلة',
                                          style: TextStyle(
                                            color: state.shareCode != null ? AppTheme.success : AppTheme.meterMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (state.tripPassengers.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              const Text('الركاب:', style: TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
                              const SizedBox(height: 4),
                              ...state.tripPassengers.map((tp) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgDeep,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      tp.status == 'dropped_off' ? Icons.check_circle : Icons.person,
                                      size: 16,
                                      color: tp.status == 'dropped_off' ? AppTheme.success : AppTheme.meterPrimary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tp.passengerName ?? 'راكب',
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      tp.status == 'pending' ? 'انتظار' :
                                      tp.status == 'picked_up' ? 'تم الصعود' : 'تم التوصيل',
                                      style: TextStyle(
                                        color: tp.status == 'dropped_off' ? AppTheme.success : AppTheme.meterMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                            ],
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

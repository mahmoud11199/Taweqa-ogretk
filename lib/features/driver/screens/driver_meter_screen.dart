import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../landing/screens/landing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import 'driver_dispatch_screen.dart';
import 'driver_wallet_screen.dart';
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
  double _speed = 42;

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(LoadDriverProfile());
    _startLocationUpdates();
    _startSimulation();
  }

  void _startSimulation() {
    Timer.periodic(const Duration(milliseconds: 800), (t) {
      if (!_tripActive) return;
      setState(() {
        _speed = (_speed + (math.Random().nextDouble() - 0.5) * 8).clamp(0, 80);
      });
    });
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
          backgroundColor: const Color(0xFF080E1C),
          body: SafeArea(
            child: Stack(
              children: [
                // Map layer
                FlutterMap(
                  mapController: _mapController,
                  options: const MapOptions(
                    initialCenter: LatLng(26.8206, 30.8025),
                    initialZoom: 13,
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
                                    ? const Color(0xFF00E5B8)
                                    : const Color(0xFFFF3B5C),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.navigation, color: Colors.white, size: 20),
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
                                    color: const Color(0xFF00E5B8),
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

                // Top gradient overlay
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 280,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color.fromRGBO(8, 13, 24, 0.97),
                          Color.fromRGBO(8, 13, 24, 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Fare meter card
                BlocBuilder<DriverBloc, DriverState>(
                  builder: (context, state) {
                    final speed = _speed;
                    final waitMode = speed < 5;
                    final fare = state.currentFare;
                    return Positioned(
                      top: 38, left: 16, right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(9, 14, 26, 0.92),
                          border: Border.all(
                            color: _tripActive
                                ? const Color.fromRGBO(255, 176, 32, 0.3)
                                : const Color(0xFF1C2B45),
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            if (_tripActive)
                              const BoxShadow(color: Color.fromRGBO(255, 176, 32, 0.08), blurRadius: 0, offset: Offset(0, 0)),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 32,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 6, height: 6,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _tripActive ? const Color(0xFFFFB020) : const Color(0xFF526480),
                                              boxShadow: _tripActive
                                                  ? [const BoxShadow(color: Color(0xFFFFB020), blurRadius: 8)]
                                                  : null,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Text('TOTAL FARE METER', style: TextStyle(
                                            fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480),
                                            letterSpacing: 0.8,
                                          )),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      _FareMeter(value: fare, isActive: _tripActive),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        if (_tripActive) {
                                          _endTrip();
                                        } else {
                                          _startTrip();
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                        decoration: BoxDecoration(
                                          color: _tripActive
                                              ? const Color.fromRGBO(255, 59, 92, 0.12)
                                              : const Color.fromRGBO(0, 229, 184, 0.12),
                                          border: Border.all(
                                            color: _tripActive
                                                ? const Color.fromRGBO(255, 59, 92, 0.4)
                                                : const Color.fromRGBO(0, 229, 184, 0.4),
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _tripActive ? Icons.pause : Icons.play_arrow,
                                              size: 13,
                                              color: _tripActive ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              _tripActive ? 'STOP' : 'START',
                                              style: TextStyle(
                                                fontSize: 12, fontWeight: FontWeight.w800,
                                                color: _tripActive ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        if (waitMode) const _Badge(label: 'WAIT', color: 'blue', dot: true),
                                        if (_tripActive) ...[
                                          const SizedBox(width: 8),
                                          const _Badge(label: 'LIVE', color: 'amber', dot: true),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            // Speed bar
                            Column(
                              children: [
                                Row(
                                  children: [
                                    const Text('SPEED', style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF526480),
                                      letterSpacing: 0.5,
                                    )),
                                    const Spacer(),
                                    Text(
                                      '${speed.toInt()} km/h${waitMode ? ' · Wait mode active' : ''}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color: waitMode ? const Color(0xFF4D9FFF) : const Color(0xFF8EA4C8),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    height: 3,
                                    child: Stack(
                                      children: [
                                        Container(height: 3, color: const Color(0xFF1C2B45)),
                                        AnimatedFractionallySizedBox(
                                          duration: const Duration(milliseconds: 500),
                                          widthFactor: (speed / 80).clamp(0.0, 1.0),
                                          child: Container(
                                            height: 3,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: waitMode
                                                    ? [const Color(0xFF4D9FFF), const Color(0xFF0066CC)]
                                                    : [const Color(0xFF00E5B8), const Color(0xFF00B896)],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 13),
                            // Stat pills
                            Container(
                              padding: const EdgeInsets.only(top: 13),
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
                              ),
                              child: Row(
                                children: [
                                  _StatPill(
                                    icon: Icons.route,
                                    label: 'Distance',
                                    value: '${state.distanceKm.toStringAsFixed(1)} km',
                                  ),
                                  Container(width: 1, height: 24, color: const Color(0xFF1C2B45)),
                                  _StatPill(
                                    icon: Icons.timer_outlined,
                                    label: 'Time',
                                    value: '${state.durationMin.toInt()} min',
                                  ),
                                  Container(width: 1, height: 24, color: const Color(0xFF1C2B45)),
                                  _StatPill(
                                    icon: Icons.pause,
                                    label: 'Wait',
                                    value: '${state.waitTimeMin.toInt()} min',
                                    color: state.waitTimeMin > 0 ? const Color(0xFF4D9FFF) : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Quick action buttons
                Positioned(
                  right: 14, top: 210,
                  child: Column(
                    children: [
                      _QuickAction(
                        icon: Icons.add,
                        color: const Color(0xFF00E5B8),
                        label: 'Add',
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverDispatchScreen())),
                      ),
                      const SizedBox(height: 9),
                      _QuickAction(
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFFF3B5C),
                        label: 'SOS',
                        onTap: () {},
                      ),
                      const SizedBox(height: 9),
                      _QuickAction(
                        icon: Icons.wifi_off,
                        color: const Color(0xFF526480),
                        label: 'Offline',
                        onTap: () {
                          context.read<DriverBloc>().add(ToggleAvailability(
                            isAvailable: !context.read<DriverBloc>().state.isAvailable,
                          ));
                        },
                      ),
                    ],
                  ),
                ),

                // Bottom sheet
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _PassengerBottomSheet(
                    tripActive: _tripActive,
                    onEndSub: (passengerId) {},
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

// ─── Fare Meter ───────────────────────────────────────────────────────────────
class _FareMeter extends StatelessWidget {
  final double value;
  final bool isActive;
  const _FareMeter({required this.value, required this.isActive});

  @override
  Widget build(BuildContext context) {
    final str = value.toStringAsFixed(2).padLeft(7, '0');
    final parts = str.split('.');
    final color = isActive ? const Color(0xFFFFB020) : const Color(0xFF3A5070);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(parts[0], style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 54,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: -2,
          height: 1,
          shadows: isActive
              ? [
                  const Shadow(color: Color.fromRGBO(255, 176, 32, 0.6), blurRadius: 28),
                  const Shadow(color: Color.fromRGBO(255, 176, 32, 0.25), blurRadius: 56),
                ]
              : null,
        )),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text('.${parts[1]}', style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: color.withValues(alpha: 0.85),
            height: 1,
            shadows: isActive
                ? [const Shadow(color: Color.fromRGBO(255, 176, 32, 0.5), blurRadius: 16)]
                : null,
          )),
        ),
        const SizedBox(width: 7),
        const Padding(
          padding: EdgeInsets.only(bottom: 3),
          child: Text('EGP', style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF526480),
            letterSpacing: 0.6,
          )),
        ),
      ],
    );
  }
}

// ─── Stat Pill ────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;
  const _StatPill({required this.icon, required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: const Color(0xFF526480)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF526480),
                letterSpacing: 0.5,
              )),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color ?? const Color(0xFF8EA4C8),
          )),
        ],
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final String color;
  final bool dot;
  const _Badge({required this.label, required this.color, this.dot = false});

  Color _fg() {
    switch (color) {
      case 'amber': return const Color(0xFFFFB020);
      case 'blue': return const Color(0xFF4D9FFF);
      case 'red': return const Color(0xFFFF3B5C);
      case 'green': return const Color(0xFF22C97A);
      default: return const Color(0xFF00E5B8);
    }
  }

  Color _bg() => _fg().withValues(alpha: 0.12);
  Color _br() => _fg().withValues(alpha: 0.25);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        border: Border.all(color: _br()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) Container(
            width: 5, height: 5,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _fg()),
          ),
          if (dot) const SizedBox(width: 5),
          Text(label, style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w700, color: _fg(),
            letterSpacing: 0.6,
          )),
        ],
      ),
    );
  }
}

// ─── Quick Action ─────────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: const Color.fromRGBO(8, 13, 24, 0.88),
          border: Border.all(color: color.withValues(alpha: 0.27)),
          borderRadius: BorderRadius.circular(13),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.4), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}

// ─── Passenger Bottom Sheet ───────────────────────────────────────────────────
class _PassengerBottomSheet extends StatefulWidget {
  final bool tripActive;
  final void Function(int passengerId) onEndSub;
  const _PassengerBottomSheet({required this.tripActive, required this.onEndSub});

  @override
  State<_PassengerBottomSheet> createState() => _PassengerBottomSheetState();
}

class _PassengerBottomSheetState extends State<_PassengerBottomSheet> {
  final _sheetController = DraggableScrollableController();

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const peek = 100.0;
    const half = 340.0;
    const full = 580.0;

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 340 / 852,
      minChildSize: 100 / 852,
      maxChildSize: 580 / 852,
      snap: true,
      snapSizes: const [100 / 852, 340 / 852, 580 / 852],
      builder: (context, scrollController) {
        final currentSize = _sheetController.size * 852;
        final isFull = currentSize >= 500;
        return Container(
          decoration: const BoxDecoration(
            color: Color.fromRGBO(9, 14, 26, 0.96),
            border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              // Drag handle
              GestureDetector(
                onTap: () {
                  if (currentSize < half) {
                    _sheetController.animateTo(half / 852, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else if (currentSize < full) {
                    _sheetController.animateTo(full / 852, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    _sheetController.animateTo(peek / 852, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(
                    color: const Color(0xFF243558),
                    borderRadius: BorderRadius.circular(2),
                  )),
                ),
              ),
              // Sheet header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Color(0xFF00E5B8)),
                    const SizedBox(width: 8),
                    const Text('Shared Passengers', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E5B8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: BlocBuilder<DriverBloc, DriverState>(
                        builder: (context, state) => Text(
                          '${state.tripPassengers.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF080D18)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 229, 184, 0.12),
                        border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, size: 12, color: Color(0xFF00E5B8)),
                          SizedBox(width: 7),
                          Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF00E5B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Passenger list
              Expanded(
                child: BlocBuilder<DriverBloc, DriverState>(
                  builder: (context, state) {
                    final passengers = state.tripPassengers;
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                      children: [
                        ...passengers.map((tp) => Container(
                          padding: const EdgeInsets.all(13),
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1628),
                            border: Border.all(color: const Color(0xFF1C2B45)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42, height: 42,
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
                                    Text(tp.passengerName ?? 'Passenger', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                                    const SizedBox(height: 2),
                                    const Text('Tahrir Sq → Zamalek', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                                    const SizedBox(height: 6),
                                    const Row(
                                      children: [
                                        Text('3.2 km', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF8EA4C8))),
                                        SizedBox(width: 12),
                                        Text('18.40 EGP', style: TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFFB020))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 59, 92, 0.1),
                                  border: Border.all(color: const Color.fromRGBO(255, 59, 92, 0.3)),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Text('End Sub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFF3B5C))),
                              ),
                            ],
                          ),
                        )),
                        // Session summary
                        if (isFull) Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0C1220),
                            border: Border.all(color: const Color(0xFF1C2B45)),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SESSION SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
                              const SizedBox(height: 10),
                              BlocBuilder<DriverBloc, DriverState>(
                                builder: (context, state) => Row(
                                  children: [
                                    const Text('Combined earnings', style: TextStyle(fontSize: 13, color: Color(0xFF8EA4C8))),
                                    const Spacer(),
                                    Text('${state.currentFare.toStringAsFixed(2)} EGP', style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00E5B8))),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00E5B8),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Checkout Trip', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF080D18))),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Bottom nav
              Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
                ),
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                child: Row(
                  children: [
                    _NavItem(icon: Icons.map, label: 'Map', active: true, onTap: () {}),
                    _NavItem(icon: Icons.calendar_month, label: 'Trips', active: false, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()));
                    }),
                    _NavItem(icon: Icons.wallet, label: 'Wallet', active: false, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverWalletScreen()));
                    }),
                    _NavItem(icon: Icons.chat, label: 'Chat', active: false, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
                    }),
                    _NavItem(icon: Icons.settings, label: 'Settings', active: false, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 20, color: active ? const Color(0xFF00E5B8) : const Color(0xFF3A5070)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? const Color(0xFF00E5B8) : const Color(0xFF3A5070))),
          ],
        ),
      ),
    );
  }
}

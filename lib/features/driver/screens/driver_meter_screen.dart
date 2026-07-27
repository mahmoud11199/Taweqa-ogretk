import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../core/config/supabase_config.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../landing/screens/landing_screen.dart';
import '../../passenger/screens/join_shared_ride_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';
import '../models/meter_data.dart';
import 'driver_dispatch_screen.dart';
import 'driver_payment_screen.dart';
import 'driver_wallet_screen.dart';
import 'earnings_screen.dart';
import 'trip_history_screen.dart';

class DriverMeterScreen extends StatefulWidget {
  final bool inTab;
  const DriverMeterScreen({super.key, this.inTab = false});

  @override
  State<DriverMeterScreen> createState() => _DriverMeterScreenState();
}

class _DriverMeterScreenState extends State<DriverMeterScreen> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _gpsTimer;
  Timer? _simulationTimer;
  Timer? _meterTickTimer;
  sb.RealtimeChannel? _requestChannel;
  final List<MeterData> _meters = [MeterData(id: 1), MeterData(id: 2)];
  int _activeMeterIndex = 0;

  MeterData get _meter => _meters[_activeMeterIndex];

  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(LoadDriverProfile());
    _startLocationUpdates();
    _startMeterTick();
    _subscribeToRideRequests();
  }

  void _subscribeToRideRequests() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    _requestChannel = SupabaseConfig.client.channel('driver-req-${user.id}')
      .onPostgresChanges(
        event: sb.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'ride_requests',
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'offered_to',
          value: user.id,
        ),
        callback: (_) {
          if (mounted) context.read<DriverBloc>().add(FetchRideRequests());
        },
      )
      .onPostgresChanges(
        event: sb.PostgresChangeEvent.update,
        schema: 'public',
        table: 'ride_requests',
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'offered_to',
          value: user.id,
        ),
        callback: (_) {
          if (mounted) context.read<DriverBloc>().add(FetchRideRequests());
        },
      )
      .subscribe();
  }

  void _startMeterTick() {
    _meterTickTimer?.cancel();
    _meterTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      for (final m in _meters) {
        if (m.isActive && !m.isPaused) {
          setState(() {});
        }
      }
    });
  }

  Future<void> _startLocationUpdates() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) showToast(context, 'يرجى منح صلاحية الموصع من الإعدادات', isError: true);
        return;
      }
    } catch (_) {
      return;
    }
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
      for (final m in _meters) {
        m.lastLat = position.latitude;
        m.lastLng = position.longitude;
        m.lastSpeedKmh = position.speed; // real speed from GPS
        m.lastAccuracy = position.accuracy;
      }
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        _mapController.camera.zoom,
      );
    }, onError: (_) {
      if (mounted) showToast(context, 'تعذر الحصول على الموقع، تأكد من تشغيل GPS', isError: true);
    });
  }

  void _updateRoute() async {
    if (!mounted) return;
    final state = context.read<DriverBloc>().state;
    if (state.currentLat == 0 || state.currentLng == 0) return;
    final m = _meter;
    if (!m.isActive) return;
    setState(() {
      m.totalDistance += 0.1;
      m.pathCoords = [...m.pathCoords, [state.currentLng, state.currentLat]];
    });
  }

  void _startMeter() {
    final s = context.read<DriverBloc>().state;
    if (s.currentLat == 0 || s.currentLng == 0) {
      showToast(context, 'لم يتم تحديد الموقع بعد', isError: true);
      return;
    }
    final m = _meter;
    if (m.isActive) return;
    setState(() {
      m.isActive = true;
      m.startTime = DateTime.now();
      m.shareCode = _generateShareCode();
    });
    _gpsTimer?.cancel();
    _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateRoute());
  }

  void _stopMeter() {
    final m = _meter;
    if (!m.isActive) return;
    setState(() {
      m.isActive = false;
      m.isPaused = false;
      m.finalFare = m.tripType == 'afrad' ? m.calculateAfradFare() : m.calculateFare();
    });
    _gpsTimer?.cancel();
    _showSettlementDialog(m);
  }

  void _togglePauseMeter() {
    final m = _meter;
    if (!m.isActive) return;
    setState(() {
      if (m.isPaused) {
        if (m.pauseStartedAt != null) {
          m.pausedDurationTotal += DateTime.now().difference(m.pauseStartedAt!);
        }
        m.isPaused = false;
        m.pauseStartedAt = null;
      } else {
        m.isPaused = true;
        m.pauseStartedAt = DateTime.now();
      }
    });
  }

  void _resetMeter() {
    final m = _meter;
    if (m.isActive) {
      showToast(context, 'أوقف العداد أولاً قبل التصفير', isError: true);
      return;
    }
    setState(() {
      _meters[_activeMeterIndex] = MeterData(id: m.id);
    });
  }

  String _generateShareCode() {
    final rng = math.Random.secure();
    return List.generate(6, (_) => rng.nextInt(10).toString()).join();
  }

  void _showSettlementDialog(MeterData m) {
    showDialog(
      context: context,
      builder: (ctx) => _SettlementDialog(
        meter: m,
        onConfirm: (adjustedMeter) {
          _showReceipt(adjustedMeter);
        },
        onCancel: () {
          setState(() {
            m.isActive = true;
            m.isPaused = false;
          });
        },
      ),
    );
  }

  void _showReceipt(MeterData m) {
    showDialog(
      context: context,
      builder: (ctx) => _ReceiptDialog(meter: m),
    );
  }

  void _switchMeter(int index) {
    if (index < 0 || index >= _meters.length) return;
    setState(() => _activeMeterIndex = index);
  }

  Widget _buildChip(String label, String type) {
    final active = _meter.tripType == type;
    return GestureDetector(
      onTap: () {
        if (_meter.isActive) return;
        setState(() => _meter.tripType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? const Color.fromRGBO(0, 229, 184, 0.12)
              : const Color.fromRGBO(255, 255, 255, 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45),
          ),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600,
          color: active ? const Color(0xFF00E5B8) : const Color(0xFF526480),
        )),
      ),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _gpsTimer?.cancel();
    _meterTickTimer?.cancel();
    _requestChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(
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
        Positioned(
          top: 38, left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(9, 14, 26, 0.92),
              border: Border.all(
                color: _meter.isActive
                    ? const Color.fromRGBO(255, 176, 32, 0.3)
                    : const Color(0xFF1C2B45),
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                if (_meter.isActive)
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
                // Meter switcher tabs
                Row(
                  children: [
                    for (var i = 0; i < _meters.length; i++)
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _switchMeter(i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _activeMeterIndex == i
                                  ? const Color.fromRGBO(255, 176, 32, 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: _activeMeterIndex == i
                                  ? Border.all(color: const Color.fromRGBO(255, 176, 32, 0.3))
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _meters[i].isActive
                                        ? const Color(0xFFFFB020)
                                        : const Color(0xFF526480),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text('عداد ${i + 1}${_meters[i].isActive ? ' · LIVE' : ''}',
                                  style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600,
                                    color: _activeMeterIndex == i
                                        ? const Color(0xFFFFB020)
                                        : const Color(0xFF526480),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Trip type toggle
                Row(
                  children: [
                    _buildChip('مخصوص', 'makhsoos'),
                    const SizedBox(width: 6),
                    _buildChip('أفراد', 'afrad'),
                    const Spacer(),
                    if (_meter.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 176, 32, 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('كود: ${_meter.shareCode ?? '-'}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFFFB020))),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                // Fare display
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
                                  color: _meter.isActive ? const Color(0xFFFFB020) : const Color(0xFF526480),
                                  boxShadow: _meter.isActive
                                      ? [const BoxShadow(color: Color(0xFFFFB020), blurRadius: 8)]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('عداد ${_activeMeterIndex + 1} · ${_meter.tripType == 'makhsoos' ? 'مخصوص' : 'أفراد'}', style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480),
                                letterSpacing: 0.8,
                              )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _FareMeter(
                            value: _meter.isActive
                                ? (_meter.tripType == 'afrad' ? _meter.calculateAfradFare() : _meter.calculateFare())
                                : _meter.finalFare,
                            isActive: _meter.isActive,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (_meter.isActive) {
                              if (_meter.isPaused) {
                                _togglePauseMeter();
                              } else {
                                _stopMeter();
                              }
                            } else {
                              _startMeter();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: _meter.isActive
                                  ? (_meter.isPaused
                                      ? const Color.fromRGBO(0, 229, 184, 0.12)
                                      : const Color.fromRGBO(255, 59, 92, 0.12))
                                  : const Color.fromRGBO(0, 229, 184, 0.12),
                              border: Border.all(
                                color: _meter.isActive
                                    ? (_meter.isPaused
                                        ? const Color.fromRGBO(0, 229, 184, 0.4)
                                        : const Color.fromRGBO(255, 59, 92, 0.4))
                                    : const Color.fromRGBO(0, 229, 184, 0.4),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _meter.isActive
                                      ? (_meter.isPaused ? Icons.play_arrow : Icons.stop)
                                      : Icons.play_arrow,
                                  size: 13,
                                  color: _meter.isActive
                                      ? (_meter.isPaused ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C))
                                      : const Color(0xFF00E5B8),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _meter.isActive ? (_meter.isPaused ? 'START' : 'STOP') : 'START',
                                  style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w800,
                                    color: _meter.isActive
                                        ? (_meter.isPaused ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C))
                                        : const Color(0xFF00E5B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Pause / Reset buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_meter.isActive && !_meter.isPaused)
                              GestureDetector(
                                onTap: _togglePauseMeter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(77, 159, 255, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('⏸', style: TextStyle(fontSize: 14)),
                                ),
                              ),
                            if (!_meter.isActive && _meter.finalFare > 0)
                              GestureDetector(
                                onTap: () => _showSettlementDialog(_meter),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(0, 229, 184, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('تسوية', style: TextStyle(fontSize: 11, color: Color(0xFF00E5B8))),
                                ),
                              ),
                            if (!_meter.isActive)
                              GestureDetector(
                                onTap: _resetMeter,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color.fromRGBO(255, 59, 92, 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('تصفير', style: TextStyle(fontSize: 11, color: Color(0xFFFF3B5C))),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Settings row (collapsible)
                if (!_meter.isActive)
                  _MeterSettings(meter: _meter, onChanged: () => setState(() {})),
                // Stats row
                Container(
                  padding: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
                  ),
                  child: Row(
                    children: [
                      _StatPill(
                        icon: Icons.route,
                        label: 'Distance',
                        value: '${_meter.totalDistance.toStringAsFixed(1)} km',
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFF1C2B45)),
                      _StatPill(
                        icon: Icons.timer_outlined,
                        label: 'Time',
                        value: '${_meter.effectiveDurationMinutes.toInt()} min',
                      ),
                      Container(width: 1, height: 24, color: const Color(0xFF1C2B45)),
                      _StatPill(
                        icon: Icons.pause,
                        label: 'Wait',
                        value: '${_meter.effectiveWaitMinutes.toInt()} min',
                        color: _meter.effectiveWaitMinutes > 0 ? const Color(0xFF4D9FFF) : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF0F1628),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFFF3B5C), size: 24),
                      SizedBox(width: 10),
                      Text('SOS', style: TextStyle(color: Color(0xFFFF3B5C), fontWeight: FontWeight.w800)),
                    ],
                  ),
                  content: const Text('هل تواجه حالة طارئة؟ يمكنك الاتصال بالطوارئ أو إرسال تنبيه للمتابعين.', style: TextStyle(color: Color(0xFF8EA4C8), height: 1.5)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF526480)))),
                    TextButton.icon(
                      onPressed: () { Navigator.pop(ctx); launchUrl(Uri.parse('tel:122'), mode: LaunchMode.externalApplication); },
                      icon: const Icon(Icons.phone, size: 16, color: Color(0xFFFF3B5C)),
                      label: const Text('اتصال بالطوارئ', style: TextStyle(color: Color(0xFFFF3B5C))),
                    ),
                  ],
                )),
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
            inTab: widget.inTab,
            tripActive: _meter.isActive,
            onEndSub: (passengerId) {
              final trip = context.read<DriverBloc>().state.currentTrip;
              if (trip != null) {
                context.read<DriverBloc>().add(UpdatePassengerStatus(
                  tripPassengerId: passengerId.toString(),
                  status: 'ended',
                ));
              }
            },
          ),
        ),
      ],
    );

    if (widget.inTab) {
      return content;
    }

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
            child: content,
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
  final bool inTab;
  final bool tripActive;
  final void Function(String passengerId) onEndSub;
  const _PassengerBottomSheet({required this.inTab, required this.tripActive, required this.onEndSub});

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
                    GestureDetector(
                      onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                        backgroundColor: const Color(0xFF0F1628),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: const Text('إضافة راكب', style: TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w700)),
                        content: const Text('شارك كود الرحلة مع الراكب ليتمكن من الانضمام', style: TextStyle(color: Color(0xFF8EA4C8))),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF526480)))),
                          TextButton(onPressed: () { Navigator.pop(ctx); Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinSharedRideScreen())); }, child: const Text('دعوة راكب', style: TextStyle(color: Color(0xFF00E5B8)))),
                        ],
                      )),
                      child: Container(
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
                              GestureDetector(
                              onTap: () {
                                showDialog(context: context, builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF0F1628),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                  title: const Text('إنهاء الاشتراك', style: TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w700)),
                                  content: const Text('هل تريد إنهاء اشتراك هذا الراكب؟', style: TextStyle(color: Color(0xFF8EA4C8))),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Color(0xFF526480)))),
                                    TextButton(onPressed: () { Navigator.pop(ctx); widget.onEndSub(tp.passengerId); }, child: const Text('تأكيد', style: TextStyle(color: Color(0xFFFF3B5C)))),
                                  ],
                                ));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color.fromRGBO(255, 59, 92, 0.1),
                                  border: Border.all(color: const Color.fromRGBO(255, 59, 92, 0.3)),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Text('End Sub', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFF3B5C))),
                              ),
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
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverPaymentScreen())),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00E5B8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text('Checkout Trip', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF080D18))),
                                  ),
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
              // Bottom nav (only when standalone)
              if (!widget.inTab) Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
                ),
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
                child: Row(
                  children: [
                    _NavItem(icon: Icons.trending_up, label: 'Earnings', active: false, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsScreen()));
                    }),
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

// ─── Meter Settings ──────────────────────────────────────────────────────────
class _MeterSettings extends StatefulWidget {
  final MeterData meter;
  final VoidCallback onChanged;
  const _MeterSettings({required this.meter, required this.onChanged});

  @override
  State<_MeterSettings> createState() => _MeterSettingsState();
}

class _MeterSettingsState extends State<_MeterSettings> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.settings, size: 12, color: Color(0xFF526480)),
                const SizedBox(width: 6),
                const Text('الإعدادات', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                const Spacer(),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more, size: 14, color: const Color(0xFF526480)),
              ],
            ),
          ),
        ),
        if (_expanded)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0C1220),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _SettingRow(label: 'سعر الكيلو', value: widget.meter.kmPrice.toString(), onChanged: (v) {
                  final val = double.tryParse(v) ?? 5;
                  widget.meter.kmPrice = val.clamp(1, 50);
                  widget.onChanged();
                }),
                const SizedBox(height: 6),
                _SettingRow(label: 'دقيقة الانتظار', value: widget.meter.waitPrice.toString(), onChanged: (v) {
                  final val = double.tryParse(v) ?? 1;
                  widget.meter.waitPrice = val.clamp(0, 20);
                  widget.onChanged();
                }),
                const SizedBox(height: 6),
                _SettingRow(label: 'دقيقة الوقت', value: widget.meter.durationPrice.toString(), onChanged: (v) {
                  final val = double.tryParse(v) ?? 0.5;
                  widget.meter.durationPrice = val.clamp(0, 10);
                  widget.onChanged();
                }),
                const SizedBox(height: 6),
                _SettingRow(label: 'البديارة', value: widget.meter.bandira.toString(), onChanged: (v) {
                  final val = double.tryParse(v) ?? 5;
                  widget.meter.bandira = val.clamp(0, 100);
                  widget.onChanged();
                }),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingRow extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  const _SettingRow({required this.label, required this.value, required this.onChanged});

  @override
  State<_SettingRow> createState() => _SettingRowState();
}

class _SettingRowState extends State<_SettingRow> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_SettingRow old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
        const Spacer(),
        SizedBox(
          width: 60,
          child: TextField(
            controller: _controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 12, color: Color(0xFFEDF2FC), fontFamily: 'monospace'),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
            ),
            onChanged: widget.onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Settlement Dialog ───────────────────────────────────────────────────────
class _SettlementDialog extends StatefulWidget {
  final MeterData meter;
  final ValueChanged<MeterData> onConfirm;
  final VoidCallback onCancel;
  const _SettlementDialog({required this.meter, required this.onConfirm, required this.onCancel});

  @override
  State<_SettlementDialog> createState() => _SettlementDialogState();
}

class _SettlementDialogState extends State<_SettlementDialog> {
  late TextEditingController _kmCtrl;
  late TextEditingController _bandiraCtrl;
  late TextEditingController _durCtrl;
  late TextEditingController _waitCtrl;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _kmCtrl = TextEditingController(text: widget.meter.kmPrice.toString());
    _bandiraCtrl = TextEditingController(text: widget.meter.bandira.toString());
    _durCtrl = TextEditingController(text: widget.meter.durationPrice.toString());
    _waitCtrl = TextEditingController(text: widget.meter.waitPrice.toString());
    _recalc();
  }

  void _recalc() {
    final km = double.tryParse(_kmCtrl.text) ?? widget.meter.kmPrice;
    final bandira = double.tryParse(_bandiraCtrl.text) ?? widget.meter.bandira;
    final dur = double.tryParse(_durCtrl.text) ?? widget.meter.durationPrice;
    final wait = double.tryParse(_waitCtrl.text) ?? widget.meter.waitPrice;
    setState(() {
      _total = bandira +
          (widget.meter.totalDistance * km) +
          (widget.meter.effectiveDurationMinutes * dur) +
          (widget.meter.effectiveWaitMinutes * wait);
      if (_total < widget.meter.minFare) _total = widget.meter.minFare;
    });
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    _bandiraCtrl.dispose();
    _durCtrl.dispose();
    _waitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1628),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.calculate, color: Color(0xFFFFB020), size: 20),
          SizedBox(width: 10),
          Text('تسوية العداد', style: TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SettleField(label: 'البديارة (ج)', ctrl: _bandiraCtrl, onChanged: (_) => _recalc()),
            const SizedBox(height: 8),
            _SettleField(label: 'سعر الكيلو (ج)', ctrl: _kmCtrl, onChanged: (_) => _recalc()),
            const SizedBox(height: 8),
            _SettleField(label: 'دقيقة الوقت (ج)', ctrl: _durCtrl, onChanged: (_) => _recalc()),
            const SizedBox(height: 8),
            _SettleField(label: 'دقيقة الانتظار (ج)', ctrl: _waitCtrl, onChanged: (_) => _recalc()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C1220),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('المسافة:', style: TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
                  const SizedBox(width: 4),
                  Text('${widget.meter.totalDistance.toStringAsFixed(1)} كم', style: const TextStyle(fontSize: 12, color: Color(0xFFEDF2FC))),
                  const Spacer(),
                  const Text('الوقت:', style: TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
                  const SizedBox(width: 4),
                  Text('${widget.meter.effectiveDurationMinutes.toInt()} د', style: const TextStyle(fontSize: 12, color: Color(0xFFEDF2FC))),
                  const Spacer(),
                  const Text('انتظار:', style: TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
                  const SizedBox(width: 4),
                  Text('${widget.meter.effectiveWaitMinutes.toInt()} د', style: const TextStyle(fontSize: 12, color: Color(0xFFEDF2FC))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 176, 32, 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color.fromRGBO(255, 176, 32, 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontSize: 14, color: Color(0xFF8EA4C8))),
                  const SizedBox(width: 8),
                  Text('${_total.toStringAsFixed(2)} ج.م', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFB020), fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { Navigator.pop(context); widget.onCancel(); },
          child: const Text('عودة', style: TextStyle(color: Color(0xFF526480))),
        ),
        TextButton.icon(
          onPressed: () {
            widget.meter.kmPrice = double.tryParse(_kmCtrl.text) ?? widget.meter.kmPrice;
            widget.meter.bandira = double.tryParse(_bandiraCtrl.text) ?? widget.meter.bandira;
            widget.meter.durationPrice = double.tryParse(_durCtrl.text) ?? widget.meter.durationPrice;
            widget.meter.waitPrice = double.tryParse(_waitCtrl.text) ?? widget.meter.waitPrice;
            widget.meter.finalFare = _total;
            Navigator.pop(context);
            widget.onConfirm(widget.meter);
          },
          icon: const Icon(Icons.check, size: 16, color: Color(0xFF00E5B8)),
          label: const Text('تسوية', style: TextStyle(color: Color(0xFF00E5B8))),
        ),
      ],
    );
  }
}

class _SettleField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final ValueChanged<String> onChanged;
  const _SettleField({required this.label, required this.ctrl, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
        const Spacer(),
        SizedBox(
          width: 80,
          child: TextField(
            controller: ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 13, color: Color(0xFFEDF2FC), fontFamily: 'monospace'),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF1C2B45))),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

// ─── Receipt Dialog ──────────────────────────────────────────────────────────
class _ReceiptDialog extends StatelessWidget {
  final MeterData meter;
  const _ReceiptDialog({required this.meter});

  @override
  Widget build(BuildContext context) {
    final fare = meter.finalFare > 0 ? meter.finalFare : meter.calculateFare();
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1628),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.receipt, color: Color(0xFF00E5B8), size: 20),
          SizedBox(width: 10),
          Text('الوصلة', style: TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w700)),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 229, 184, 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('عداد ${meter.id} · ${meter.tripType == 'makhsoos' ? 'مخصوص' : 'أفراد'}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF00E5B8))),
              ),
            ),
            if (meter.shareCode != null) ...[
              const SizedBox(height: 8),
              Center(
                child: Text('كود الرحلة: ${meter.shareCode}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFFFFB020))),
              ),
            ],
            const SizedBox(height: 14),
            _receiptRow('المسافة', '${meter.totalDistance.toStringAsFixed(1)} كم'),
            _receiptRow('الوقت', '${meter.effectiveDurationMinutes.toInt()} دقيقة'),
            _receiptRow('انتظار', '${meter.effectiveWaitMinutes.toInt()} دقيقة'),
            _receiptRow('السعر/كم', '${meter.kmPrice.toStringAsFixed(2)} ج'),
            _receiptRow('البديارة', '${meter.bandira.toStringAsFixed(2)} ج'),
            if (meter.tripType == 'afrad') ...[
              const Divider(color: Color(0xFF1C2B45)),
              const Text('الركاب:', style: TextStyle(fontSize: 11, color: Color(0xFF8EA4C8))),
              for (var i = 0; i < meter.passengers.length; i++)
                if (!meter.passengers[i].exited)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('${meter.passengers[i].name} — ${meter.passengers[i].fare.toStringAsFixed(2)} ج',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEDF2FC))),
                  ),
            ],
            const Divider(color: Color(0xFF1C2B45), height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 229, 184, 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('الإجمالي:', style: TextStyle(fontSize: 14, color: Color(0xFF8EA4C8))),
                  const SizedBox(width: 8),
                  Text('${fare.toStringAsFixed(2)} ج.م',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8), fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق', style: TextStyle(color: Color(0xFF526480))),
        ),
TextButton.icon(
  onPressed: () {
    final text = 'توقع أجرتك — وصل العداد ${meter.id}\n'
        'النوع: ${meter.tripType == 'makhsoos' ? 'مخصوص' : 'أفراد'}\n'
        'المسافة: ${meter.totalDistance.toStringAsFixed(1)} كم\n'
        'الوقت: ${meter.effectiveDurationMinutes.toInt()} د\n'
        'الإجمالي: ${fare.toStringAsFixed(2)} ج.م';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ الوصلة')),
    );
  },
          icon: const Icon(Icons.share, size: 16, color: Color(0xFF00E5B8)),
          label: const Text('مشاركة', style: TextStyle(color: Color(0xFF00E5B8))),
        ),
      ],
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF8EA4C8))),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFFEDF2FC), fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

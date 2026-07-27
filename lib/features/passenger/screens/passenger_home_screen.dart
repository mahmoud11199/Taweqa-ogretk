import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/services/sos_service.dart';
import '../../../core/widgets/toast_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../landing/screens/landing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../rating/screens/rating_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../subscription/screens/subscription_plans_screen.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';
import 'join_shared_ride_screen.dart';
import 'my_scheduled_trips_screen.dart';
import 'ride_history_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final MapController _mapController = MapController();
  double _currentLat = 26.8206;
  double _currentLng = 30.8025;
  bool _isSelectingDestination = false;
  bool _drawerOpen = false;
  sb.RealtimeChannel? _driverTrackingChannel;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _driverTrackingChannel?.unsubscribe();
    super.dispose();
  }

  void _startDriverTracking(String driverId) {
    _driverTrackingChannel?.unsubscribe();
    _driverTrackingChannel = SupabaseConfig.client.channel('driver-location-$driverId')
      ..onPostgresChanges(
        event: sb.PostgresChangeEvent.update,
        schema: 'public',
        table: 'driver_locations',
        filter: sb.PostgresChangeFilter(
          type: sb.PostgresChangeFilterType.eq,
          column: 'driver_id',
          value: driverId,
        ),
        callback: (payload) {
          if (!mounted) return;
          final newData = payload.newRecord;
          if (newData['lat'] != null && newData['lng'] != null) {
            context.read<PassengerBloc>().add(UpdateDriverTracking(
              lat: (newData['lat'] as num).toDouble(),
              lng: (newData['lng'] as num).toDouble(),
            ));
          }
        },
      )
      ..subscribe();
  }

  Future<void> _getCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (mounted) showToast(context, 'يرجى منح صلاحية الموقع من الإعدادات', isError: true);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (mounted) showToast(context, 'صلاحية الموقع ملغاة نهائياً. يرجى تفعيلها من الإعدادات', isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      _currentLat = pos.latitude;
      _currentLng = pos.longitude;
      context.read<PassengerBloc>().add(UpdatePickupLocation(
        lat: _currentLat, lng: _currentLng, address: 'موقعي الحالي',
      ));
      context.read<PassengerBloc>().add(LoadNearbyDrivers(lat: _currentLat, lng: _currentLng));
      _mapController.move(LatLng(_currentLat, _currentLng), 14);
    } on TimeoutException {
      if (mounted) showToast(context, 'تعذر الحصول على الموقع، تأكد من تشغيل GPS', isError: true);
    } catch (_) {
      if (mounted) showToast(context, 'تعذر الحصول على الموقع، يرجى المحاولة مرة أخرى', isError: true);
    }
  }

  void _requestRide() {
    final s = context.read<PassengerBloc>().state;
    if (s.pickupLat == null) {
      showToast(context, 'يرجى تحديد موقع الالتقاط', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(RequestRide(
      pickupLat: s.pickupLat!, pickupLng: s.pickupLng!,
      pickupAddress: s.pickupAddress, destLat: s.destLat,
      destLng: s.destLng, destAddress: s.destAddress,
    ));
  }

  void _scheduleRide() async {
    final s = context.read<PassengerBloc>().state;
    if (s.pickupLat == null) {
      showToast(context, 'يرجى تحديد موقع الالتقاط', isError: true);
      return;
    }
    final date = await showDatePicker(
      context: context, initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    context.read<PassengerBloc>().add(ScheduleRide(
      pickupLat: s.pickupLat!, pickupLng: s.pickupLng!,
      pickupAddress: s.pickupAddress, destLat: s.destLat,
      destLng: s.destLng, destAddress: s.destAddress, scheduledAt: scheduledAt,
    ));
    if (mounted) showToast(context, 'تم جدولة الرحلة بنجاح');
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LandingScreen()), (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF00E5B8)),
            onPressed: () => setState(() => _drawerOpen = !_drawerOpen),
          ),
          title: const Text('ركوب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.my_location, color: Color(0xFF00E5B8)),
              onPressed: _getCurrentLocation,
            ),
          ],
        ),
        drawer: _drawerOpen ? _buildDrawer() : null,
        body: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_currentLat, _currentLng),
                initialZoom: 14,
                onTap: (tapPos, latlng) {
                  if (_isSelectingDestination) {
                    context.read<PassengerBloc>().add(UpdateDestination(
                      lat: latlng.latitude, lng: latlng.longitude, address: 'الوجهة المحددة',
                    ));
                    setState(() => _isSelectingDestination = false);
                  } else {
                    context.read<PassengerBloc>().add(UpdatePickupLocation(
                      lat: latlng.latitude, lng: latlng.longitude, address: 'موقع محدد',
                    ));
                  }
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
                        if (state.pickupLat != null && state.pickupLng != null)
                          Marker(
                            point: LatLng(state.pickupLat!, state.pickupLng!),
                            width: 40, height: 40,
                            child: const Icon(Icons.location_on, color: Color(0xFF00E5B8), size: 36),
                          ),
                        if (state.destLat != null)
                          Marker(
                            point: LatLng(state.destLat!, state.destLng!),
                            width: 40, height: 40,
                            child: const Icon(Icons.flag, color: Color(0xFFFFB020), size: 36),
                          ),
                        ...state.nearbyDrivers.where((d) =>
                          d['current_lat'] != null && d['current_lng'] != null
                        ).map((d) => Marker(
                          point: LatLng(
                            (d['current_lat'] as num).toDouble(),
                            (d['current_lng'] as num).toDouble(),
                          ),
                          width: 30, height: 30,
                          child: const Icon(Icons.local_taxi, color: Color(0xFF0088CC), size: 24),
                        )),
                        if (state.driverLat != null && state.driverLng != null)
                          Marker(
                            point: LatLng(state.driverLat!, state.driverLng!),
                            width: 36, height: 36,
                            child: const Icon(Icons.directions_car, color: Color(0xFF00E5B8), size: 32),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
            // Bottom overlay
            BlocBuilder<PassengerBloc, PassengerState>(
              builder: (context, state) {
                if (state.activeRequest != null) {
                  return _buildActiveRideCard(state);
                }
                return _buildRequestCard(state);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: const Color(0xFF080D18),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF1C2B45))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF080D18), size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text('توقع أجرتك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                  const SizedBox(height: 4),
                  const Text('راكب', style: TextStyle(fontSize: 14, color: Color(0xFF526480))),
                ],
              ),
            ),
            _DrawerItem(icon: Icons.map, label: 'الصفحة الرئيسية', onTap: () => setState(() => _drawerOpen = false)),
            _DrawerItem(icon: Icons.history, label: 'سجل الرحلات', onTap: () {
              setState(() => _drawerOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
            }),
            _DrawerItem(icon: Icons.wallet, label: 'المحفظة', onTap: () {
              setState(() => _drawerOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            }),
            _DrawerItem(icon: Icons.subscriptions, label: 'الباقات', onTap: () {
              setState(() => _drawerOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()));
            }),
            _DrawerItem(icon: Icons.chat, label: 'الدردشة', onTap: () {
              setState(() => _drawerOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen()));
            }),
            _DrawerItem(icon: Icons.settings, label: 'الإعدادات', onTap: () {
              setState(() => _drawerOpen = false);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),
            const Divider(color: Color(0xFF1C2B45)),
            _DrawerItem(icon: Icons.logout, label: 'تسجيل الخروج', color: const Color(0xFFFF3B5C), onTap: () {
              setState(() => _drawerOpen = false);
              context.read<AuthBloc>().add(LogoutRequested());
            }),
          ],
        ),
      ),
    );
  }

  // ── Request Card ──────────────────────────────────────────────────────────
  Widget _buildRequestCard(PassengerState state) {
    return Positioned(
      left: 16, right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1628),
          border: Border.all(color: const Color(0xFF1C2B45)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.5), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pickup
            Row(
              children: [
                const Icon(Icons.my_location, size: 16, color: Color(0xFF00E5B8)),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  state.pickupAddress.isNotEmpty ? state.pickupAddress : 'موقع الالتقاط',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC)),
                )),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(width: 24),
                  Column(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('│', style: TextStyle(color: Color(0xFF1C2B45), fontSize: 16, height: 0.4)),
                      ),
                      SizedBox(
                        width: 20,
                        child: Text('│', style: TextStyle(color: Color(0xFF1C2B45), fontSize: 16, height: 0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Destination
            GestureDetector(
              onTap: () {
                if (state.destLat != null) {
                  setState(() => _isSelectingDestination = true);
                } else {
                  setState(() => _isSelectingDestination = !_isSelectingDestination);
                }
              },
              child: Row(
                children: [
                  Icon(
                    _isSelectingDestination ? Icons.edit_location : Icons.flag,
                    size: 16,
                    color: _isSelectingDestination ? const Color(0xFF0088CC) : const Color(0xFFFFB020),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    state.destAddress ?? (_isSelectingDestination ? 'اختر الوجهة على الخريطة...' : 'الوجهة (اختياري)'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: state.destAddress != null ? const Color(0xFFEDF2FC) : const Color(0xFF526480),
                    ),
                  )),

                ],
              ),
            ),
            const SizedBox(height: 14),
            // Fare estimate
            if (state.estimatedFare != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 229, 184, 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.15)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.monetization_on, size: 18, color: Color(0xFF00E5B8)),
                      const SizedBox(width: 8),
                      const Text('التكلفة التقديرية: ', style: TextStyle(fontSize: 13, color: Color(0xFF8EA4C8))),
                      Text('${state.estimatedFare!.toStringAsFixed(0)} EGP', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'monospace', color: Color(0xFF00E5B8))),
                      const Spacer(),
                      if (state.estimatedDistance != null)
                        Text('${(state.estimatedDistance! / 1000).toStringAsFixed(1)} كم', style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                    ],
                  ),
                ),
              ),
            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _requestRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E5B8),
                        foregroundColor: const Color(0xFF080D18),
                        disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: state.isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                          : const Text('طلب رحلة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _scheduleRide,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(0, 229, 184, 0.1),
                      foregroundColor: const Color(0xFF00E5B8),
                      disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      side: const BorderSide(color: Color.fromRGBO(0, 229, 184, 0.25)),
                    ),
                    child: const Text('جدولة', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const JoinSharedRideScreen())),
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text('رحلة تشاركية', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF526480),
                        side: const BorderSide(color: Color(0xFF1C2B45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyScheduledTripsScreen())),
                      icon: const Icon(Icons.calendar_month, size: 16),
                      label: const Text('المجدولة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF526480),
                        side: const BorderSide(color: Color(0xFF1C2B45)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Ride Card ──────────────────────────────────────────────────────
  Widget _buildActiveRideCard(PassengerState state) {
    final req = state.activeRequest!;
    final bool isAccepted = req.status == 'accepted';
    final bool isStarted = req.status == 'started';
    final bool isCompleted = req.status == 'completed';
    final bool isTracking = isAccepted || isStarted;

    if (isTracking && state.driverLat == null) {
      _startDriverTracking(req.driverId ?? req.id);
    }

    final int progressIndex = req.status == 'accepted' ? 1 : req.status == 'started' ? 2 : req.status == 'completed' ? 3 : 0;
    final String statusText = req.status == 'searching' ? 'جاري البحث عن سائق...' :
                              req.status == 'accepted' ? 'السائق في الطريق إليك' :
                              req.status == 'started' ? 'الرحلة جارية' : 'الرحلة منتهية';
    final String statusDesc = req.status == 'searching' ? 'جارٍ العثور على سائق قريب' :
                              req.status == 'accepted' ? 'وصول السائق خلال 3-5 دقائق' :
                              req.status == 'started' ? 'متجه إلى الوجهة' : 'شكرًا لاستخدامك توقع أجرتك';

    return Positioned(
      left: 16, right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1628),
          border: Border.all(color: const Color(0xFF1C2B45)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.5), blurRadius: 24, offset: Offset(0, 8))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 229, 184, 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    req.status == 'searching' ? Icons.hourglass_top :
                    isAccepted ? Icons.person_pin :
                    isStarted ? Icons.directions_car : Icons.star,
                    color: const Color(0xFF00E5B8), size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(statusText, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                    const SizedBox(height: 2),
                    Text(statusDesc, style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                  ],
                )),
              ],
            ),
            // Progress steps (only when accepted or started)
            if (isTracking) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStep('تم القبول', progressIndex >= 1, Icons.check_circle),
                  _buildStepLine(progressIndex >= 1),
                  _buildStep('وصل السائق', progressIndex >= 2, isAccepted ? Icons.schedule : Icons.check_circle),
                  _buildStepLine(progressIndex >= 2),
                  _buildStep('جاري التوصيل', progressIndex >= 3, isStarted && !isCompleted ? Icons.directions_car : Icons.check_circle),
                  _buildStepLine(progressIndex >= 3),
                  _buildStep('تم', progressIndex >= 4, Icons.flag),
                ],
              ),
              // ETA row
              if (state.driverLat != null && state.pickupLat != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined, color: Color(0xFF00E5B8), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'المسافة المتبقية: ${_calculateDistance(state).toStringAsFixed(1)} كم',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF8BA4C0)),
                      ),
                    ],
                  ),
                ),
            ],
            if (req.status == 'searching')
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => context.read<PassengerBloc>().add(CancelRide(req.id)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(255, 59, 92, 0.1),
                      foregroundColor: const Color(0xFFFF3B5C),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      side: const BorderSide(color: Color.fromRGBO(255, 59, 92, 0.25)),
                    ),
                    child: const Text('إلغاء الطلب', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            if (isTracking)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                          icon: const Icon(Icons.chat, size: 16),
                          label: const Text('دردشة', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(0, 229, 184, 0.1),
                            foregroundColor: const Color(0xFF00E5B8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            side: const BorderSide(color: Color.fromRGBO(0, 229, 184, 0.25)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final user = SupabaseConfig.client.auth.currentUser;
                            if (user != null) {
                              SosService.sendAlert(
                                userId: user.id,
                                lat: state.pickupLat ?? 0,
                                lng: state.pickupLng ?? 0,
                                message: 'طلب نجدة من الراكب',
                              );
                            }
                            await launchUrl(Uri.parse('tel:122'));
                          },
                          icon: const Icon(Icons.warning_amber_rounded, size: 16),
                          label: const Text('SOS', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(255, 59, 92, 0.1),
                            foregroundColor: const Color(0xFFFF3B5C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                            side: const BorderSide(color: Color.fromRGBO(255, 59, 92, 0.25)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(
                        requestId: req.id, driverName: req.driverName ?? 'السائق',
                      )));
                    },
                    icon: const Icon(Icons.star, size: 18),
                    label: const Text('تقييم السائق', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFB020),
                      foregroundColor: const Color(0xFF080D18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String label, bool active, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: active ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: active ? const Color(0xFF00E5B8) : const Color(0xFF526480))),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      height: 2,
      width: 12,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  double _calculateDistance(PassengerState state) {
    if (state.driverLat == null || state.driverLng == null || state.pickupLat == null || state.pickupLng == null) return 0;
    const distance = Distance();
    return distance(
      LatLng(state.driverLat!, state.driverLng!),
      LatLng(state.pickupLat!, state.pickupLng!),
    ) / 1000;
  }
}

// ─── Drawer Item ──────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _DrawerItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFFEDF2FC);
    return ListTile(
      leading: Icon(icon, color: color ?? const Color(0xFF00E5B8), size: 20),
      title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c)),
      onTap: onTap,
      horizontalTitleGap: 8,
    );
  }
}

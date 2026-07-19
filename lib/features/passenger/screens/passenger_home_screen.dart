import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../landing/screens/landing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
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
    } catch (_) {
      if (mounted) showToast(context, 'تعذر الحصول على الموقع', isError: true);
    }
  }

  void _requestRide() {
    final state = context.read<PassengerBloc>().state;
    if (state.pickupLat == null) {
      showToast(context, 'يرجى تحديد موقع الالتقاط', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(RequestRide(
      pickupLat: state.pickupLat!,
      pickupLng: state.pickupLng!,
      pickupAddress: state.pickupAddress,
      destLat: state.destLat,
      destLng: state.destLng,
      destAddress: state.destAddress,
    ));
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
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
      drawer: Drawer(
        child: Container(
          color: AppTheme.bgDeep,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(color: AppTheme.meterCard),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.person, size: 48, color: AppTheme.meterPrimary),
                    SizedBox(height: 8),
                    Text('توقع أجرتك', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('راكب', style: TextStyle(color: AppTheme.meterMuted, fontSize: 13)),
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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryScreen()));
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
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(_currentLat, _currentLng),
              initialZoom: 14,
              onTap: (tapPos, latlng) {
                if (_isSelectingDestination) {
                  context.read<PassengerBloc>().add(UpdateDestination(
                    lat: latlng.latitude,
                    lng: latlng.longitude,
                    address: 'الوجهة المحددة',
                  ));
                  setState(() => _isSelectingDestination = false);
                } else {
                  context.read<PassengerBloc>().add(UpdatePickupLocation(
                    lat: latlng.latitude,
                    lng: latlng.longitude,
                    address: 'موقع محدد',
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
                      ...state.nearbyDrivers.where((d) =>
                        d['current_lat'] != null && d['current_lng'] != null
                      ).map((d) => Marker(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.my_location, color: AppTheme.meterPrimary, size: 28),
                    onPressed: _getCurrentLocation,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.meterCard,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
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
                        decoration: InputDecoration(
                          hintText: _isSelectingDestination ? 'اختر الوجهة على الخريطة...' : 'الوجهة (اختياري)',
                          prefixIcon: Icon(Icons.flag, color: AppTheme.error),
                          suffixIcon: Icon(
                            _isSelectingDestination ? Icons.my_location : Icons.edit_location,
                            color: _isSelectingDestination ? AppTheme.accent : AppTheme.meterMuted,
                            size: 20,
                          ),
                          filled: true,
                          fillColor: AppTheme.bgDeep,
                        ),
                        enabled: false,
                        onTap: () => setState(() => _isSelectingDestination = !_isSelectingDestination),
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
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}

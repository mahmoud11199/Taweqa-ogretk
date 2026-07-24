import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../chat/screens/chat_list_screen.dart';
import '../../landing/screens/landing_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'driver_meter_screen.dart';
import 'driver_wallet_screen.dart';
import 'earnings_screen.dart';
import 'trip_history_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DriverMeterScreen(inTab: true),
    EarningsScreen(inTab: true),
    TripHistoryScreen(inTab: true),
    DriverWalletScreen(inTab: true),
    ChatListScreen(inTab: true),
    SettingsScreen(inTab: true),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LandingScreen()),
              (route) => false,
            );
          }
        },
        child: Scaffold(
          extendBody: true,
          backgroundColor: const Color(0xFF080E1C),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              backgroundColor: const Color.fromRGBO(9, 14, 26, 0.98),
              selectedItemColor: const Color(0xFF00E5B8),
              unselectedItemColor: const Color(0xFF3A5070),
              type: BottomNavigationBarType.fixed,
              selectedFontSize: 11,
              unselectedFontSize: 11,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.speed), label: 'العداد'),
                BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'الأرباح'),
                BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'الرحلات'),
                BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'المحفظة'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'الدردشة'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/helpers.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../../landing/screens/landing_screen.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'drivers_management_screen.dart';
import 'passengers_management_screen.dart';
import 'trips_management_screen.dart';
import 'driver_applications_screen.dart';
import 'app_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadAdminStats());
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
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('لوحة التحكم', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFFFF3B5C)),
              onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            ),
          ],
        ),
        body: BlocBuilder<AdminBloc, AdminState>(
          builder: (context, state) {
            if (state.isLoading && state.stats == null) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
            }
            final stats = state.stats;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (stats != null) _buildRevenueCard(stats),
                  const SizedBox(height: 20),
                  // Stats grid
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.directions_car, label: 'السائقين', value: '${stats?.totalDrivers ?? 0}', subtitle: '${stats?.availableDrivers ?? 0} نشط', color: const Color(0xFF00E5B8))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(icon: Icons.people, label: 'الركاب', value: '${stats?.totalPassengers ?? 0}', subtitle: 'إجمالي', color: const Color(0xFF0088CC))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _StatCard(icon: Icons.route, label: 'رحلات نشطة', value: '${stats?.activeTrips ?? 0}', subtitle: 'قيد التشغيل', color: const Color(0xFFFFB020))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(icon: Icons.check_circle, label: 'مكتملة', value: '${stats?.completedTrips ?? 0}', subtitle: 'إجمالي', color: const Color(0xFF00E5B8))),
                      const SizedBox(width: 8),
                      Expanded(child: _StatCard(icon: Icons.pending_actions, label: 'طلبات معلقة', value: '${stats?.pendingApplications ?? 0}', subtitle: 'تسجيل سائقين', color: const Color(0xFFFF3B5C))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text('الإدارة', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.4)),
                  const SizedBox(height: 12),
                  _MenuTile(
                    icon: Icons.directions_car, label: 'إدارة السائقين', badge: '${stats?.totalDrivers ?? 0}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversManagementScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.people, label: 'إدارة الركاب', badge: '${stats?.totalPassengers ?? 0}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengersManagementScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.route, label: 'إدارة الرحلات', badge: '${stats?.activeTrips ?? 0}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsManagementScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.pending_actions, label: 'طلبات التسجيل', badge: '${stats?.pendingApplications ?? 0}',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverApplicationsScreen())),
                  ),
                  _MenuTile(
                    icon: Icons.settings, label: 'إعدادات التطبيق',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppSettingsScreen())),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRevenueCard(stats) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001A14), Color(0xFF002E22), Color(0xFF001E30)],
        ),
        border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40, top: -40,
            child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(0, 229, 184, 0.04))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إجمالي الإيرادات', style: TextStyle(fontSize: 12, color: Color(0xFF526480))),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(formatCurrency(stats.totalRevenue), style: const TextStyle(fontFamily: 'monospace', fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF00E5B8), height: 1)),
                  const SizedBox(width: 6),
                  const Text('إيرادات', style: TextStyle(fontSize: 13, color: Color(0xFF526480))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _RevenuePill(icon: Icons.people, label: '${stats.totalPassengers ?? 0} راكب'),
                  const SizedBox(width: 12),
                  _RevenuePill(icon: Icons.directions_car, label: '${stats.totalDrivers ?? 0} سائق'),
                  const SizedBox(width: 12),
                  _RevenuePill(icon: Icons.check_circle, label: '${stats.completedTrips ?? 0} رحلة'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.icon, required this.label, required this.value,
    required this.subtitle, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w900, color: color, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8EA4C8))),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: Color(0xFF526480))),
        ],
      ),
    );
  }
}

// ─── Revenue Pill ──────────────────────────────────────────────────────────────
class _RevenuePill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _RevenuePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(0, 229, 184, 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF00E5B8)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF8EA4C8))),
        ],
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon, required this.label, this.badge, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(0, 229, 184, 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF00E5B8), size: 18),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null && badge != '0')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 176, 32, 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(badge!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFFFB020))),
              ),
            if (badge != null && badge != '0') const SizedBox(width: 6),
            const Icon(Icons.chevron_left, color: Color(0xFF3A5070), size: 18),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}

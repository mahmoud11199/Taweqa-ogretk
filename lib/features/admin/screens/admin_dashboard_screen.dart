import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
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
            MaterialPageRoute(builder: (_) => const LandingScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('لوحة التحكم'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.stats == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          final stats = state.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats != null)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.meterPrimary, AppTheme.accent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Text('إجمالي الإيرادات',
                            style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(formatCurrency(stats.totalRevenue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            )),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.directions_car,
                        label: 'السائقين',
                        value: '${stats?.totalDrivers ?? 0}',
                        subtitle: '${stats?.availableDrivers ?? 0} متاح',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.people,
                        label: 'الركاب',
                        value: '${stats?.totalPassengers ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.route,
                        label: 'رحلات نشطة',
                        value: '${stats?.activeTrips ?? 0}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.pending_actions,
                        label: 'طلبات معلقة',
                        value: '${stats?.pendingApplications ?? 0}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('الإدارة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.directions_car,
                  label: 'إدارة السائقين',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriversManagementScreen())),
                ),
                _MenuTile(
                  icon: Icons.people,
                  label: 'إدارة الركاب',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassengersManagementScreen())),
                ),
                _MenuTile(
                  icon: Icons.route,
                  label: 'إدارة الرحلات',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripsManagementScreen())),
                ),
                _MenuTile(
                  icon: Icons.pending_actions,
                  label: 'طلبات التسجيل',
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverApplicationsScreen())),
                ),
              ],
            ),
          );
        },
      ),
    ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.meterCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.meterPrimary, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              )),
          Text(label,
              style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13)),
          if (subtitle != null)
            Text(subtitle!,
                style: const TextStyle(color: AppTheme.meterMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.meterPrimary),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.chevron_left, color: AppTheme.meterMuted),
        tileColor: AppTheme.meterCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

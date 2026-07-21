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

enum _AdminPage { dashboard, drivers, passengers, trips, applications, settings }

class AdminWebScreen extends StatefulWidget {
  const AdminWebScreen({super.key});

  @override
  State<AdminWebScreen> createState() => _AdminWebScreenState();
}

class _AdminWebScreenState extends State<AdminWebScreen> {
  _AdminPage _page = _AdminPage.dashboard;

  @override
  void initState() {
    super.initState();
    final bloc = context.read<AdminBloc>();
    bloc.add(LoadAdminStats());
    bloc.add(LoadDrivers());
    bloc.add(LoadPassengers());
    bloc.add(LoadTrips());
    bloc.add(LoadDriverApplications());
    bloc.add(LoadAppSettings());
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
        backgroundColor: const Color(0xFF080D18),
        body: Row(
          children: [
            _Sidebar(page: _page, onChanged: (p) => setState(() => _page = p)),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_page) {
      case _AdminPage.dashboard: return const _DashboardContent();
      case _AdminPage.drivers: return const _DriversContent();
      case _AdminPage.passengers: return const _PassengersContent();
      case _AdminPage.trips: return const _TripsContent();
      case _AdminPage.applications: return const _ApplicationsContent();
      case _AdminPage.settings: return const _SettingsContent();
    }
  }
}

class _Sidebar extends StatelessWidget {
  final _AdminPage page;
  final ValueChanged<_AdminPage> onChanged;
  const _Sidebar({required this.page, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF080D18),
        border: Border(right: BorderSide(color: Color(0xFF0F1628), width: 1)),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: const Color(0xFF00E5B8).withAlpha(30), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.admin_panel_settings, size: 18, color: Color(0xFF00E5B8)),
                ),
                const SizedBox(width: 10),
                const Text('لوحة التحكم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
              ],
            ),
          ),
          const Divider(color: Color(0xFF0F1628), height: 1),
          const SizedBox(height: 12),
          ..._navItems.map((item) => _NavItem(
                icon: item.icon, label: item.label,
                selected: page == item.page,
                onTap: () => onChanged(item.page),
              )),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('تسجيل الخروج'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B5C),
                  side: const BorderSide(color: Color(0xFFFF3B5C)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  final _AdminPage page;
  const _NavItemData({required this.icon, required this.label, required this.page});
}

const _navItems = [
  _NavItemData(icon: Icons.dashboard, label: 'الإحصائيات', page: _AdminPage.dashboard),
  _NavItemData(icon: Icons.directions_car, label: 'السائقين', page: _AdminPage.drivers),
  _NavItemData(icon: Icons.people, label: 'الركاب', page: _AdminPage.passengers),
  _NavItemData(icon: Icons.route, label: 'الرحلات', page: _AdminPage.trips),
  _NavItemData(icon: Icons.pending_actions, label: 'طلبات التسجيل', page: _AdminPage.applications),
  _NavItemData(icon: Icons.settings, label: 'الإعدادات', page: _AdminPage.settings),
];

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected ? const Color(0xFF00E5B8).withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: selected ? const Color(0xFF00E5B8) : const Color(0xFF526480)),
                const SizedBox(width: 12),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF00E5B8) : const Color(0xFF526480))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإحصائيات'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.stats == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final stats = state.stats;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (stats != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('إجمالي الإيرادات', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 6),
                        Text(formatCurrency(stats.totalRevenue), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16, runSpacing: 16,
                  children: [
                    _StatCard(icon: Icons.directions_car, label: 'السائقين', value: '${stats?.totalDrivers ?? 0}', subtitle: '${stats?.availableDrivers ?? 0} متاح'),
                    _StatCard(icon: Icons.people, label: 'الركاب', value: '${stats?.totalPassengers ?? 0}'),
                    _StatCard(icon: Icons.route, label: 'رحلات نشطة', value: '${stats?.activeTrips ?? 0}'),
                    _StatCard(icon: Icons.pending_actions, label: 'طلبات معلقة', value: '${stats?.pendingApplications ?? 0}'),
                    _StatCard(icon: Icons.checklist, label: 'رحلات مكتملة', value: '${stats?.completedTrips ?? 0}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final String? subtitle;
  const _StatCard({required this.icon, required this.label, required this.value, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF0F1628), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1C2B45))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: const Color(0xFF00E5B8), size: 28),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 28, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Color(0xFF526480), fontSize: 13)),
        if (subtitle != null) Text(subtitle!, style: const TextStyle(color: Color(0xFF526480), fontSize: 11)),
      ]),
    );
  }
}

class _DriversContent extends StatelessWidget {
  const _DriversContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة السائقين'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final drivers = state.drivers;
          return Column(
            children: [
              _DataTableWidget(
                columns: const ['الاسم', 'الهاتف', 'النوع', 'السيارة', 'اللوحة', 'حالة', 'حظر'],
                rows: drivers.map((d) => [
                  d.fullName, d.phone ?? '-', d.driverType ?? '-',
                  d.carModel ?? '-', d.carPlate ?? '-',
                  d.isAvailable ? 'متاح' : 'مشغول',
                  d.banned ? 'محظور' : 'نشط',
                ]).toList(),
              ),
              const SizedBox(height: 16),
              ...drivers.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(d.fullName, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 13))),
                    TextButton.icon(
                      onPressed: () => context.read<AdminBloc>().add(ToggleDriverBan(userId: d.id, banned: !d.banned)),
                      icon: Icon(d.banned ? Icons.lock_open : Icons.lock, size: 16),
                      label: Text(d.banned ? 'إلغاء الحظر' : 'حظر', style: const TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: d.banned ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C)),
                    ),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

class _PassengersContent extends StatelessWidget {
  const _PassengersContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الركاب'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final passengers = state.passengers;
          return _DataTableWidget(
            columns: const ['الاسم', 'الهاتف', 'البريد', 'تاريخ التسجيل'],
            rows: passengers.map((p) {
              final m = p as Map<String, dynamic>;
              return [
                m['full_name'] as String? ?? '-',
                m['phone'] as String? ?? '-',
                m['email'] as String? ?? '-',
                (m['created_at'] as String?)?.substring(0, 10) ?? '-',
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}

class _TripsContent extends StatelessWidget {
  const _TripsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الرحلات'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final trips = state.trips;
          return _DataTableWidget(
            columns: const ['المعرف', 'الحالة', 'المسافة', 'الأجرة', 'التاريخ'],
            rows: trips.map((t) {
              final m = t as Map<String, dynamic>;
              return [
                (m['id'] as String).substring(0, 8),
                m['status'] as String? ?? '-',
                '${(m['distance_km'] as num?)?.toStringAsFixed(1) ?? '-'} كم',
                '${(m['fare'] as num?)?.toStringAsFixed(2) ?? '-'} ج.م',
                (m['created_at'] as String?)?.substring(0, 10) ?? '-',
              ];
            }).toList(),
          );
        },
      ),
    );
  }
}

class _ApplicationsContent extends StatelessWidget {
  const _ApplicationsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('طلبات تسجيل السائقين'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final apps = state.driverApplications;
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: apps.length,
            itemBuilder: (_, i) {
              final app = apps[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0F1628), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF1C2B45))),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: const Color(0xFF00E5B8).withAlpha(20), borderRadius: BorderRadius.circular(10)),
                      child: Center(child: Text('${i + 1}', style: const TextStyle(color: Color(0xFF00E5B8), fontWeight: FontWeight.w700))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.fullName, style: const TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w600, fontSize: 14)),
                      if (app.phone != null) Text(app.phone!, style: const TextStyle(color: Color(0xFF526480), fontSize: 12)),
                      Text(app.createdAt.toString().substring(0, 16), style: const TextStyle(color: Color(0xFF526480), fontSize: 11)),
                    ])),
                    _AppStatusBadge(status: app.status),
                    const SizedBox(width: 12),
                    if (app.status == 'pending') ...[
                      IconButton(icon: const Icon(Icons.check_circle, color: Color(0xFF00E5B8)), onPressed: () => context.read<AdminBloc>().add(ApproveDriver(app.userId))),
                      IconButton(icon: const Icon(Icons.cancel, color: Color(0xFFFF3B5C)), onPressed: () => context.read<AdminBloc>().add(RejectDriver(app.userId))),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AppStatusBadge extends StatelessWidget {
  final String status;
  const _AppStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == 'approved' ? const Color(0xFF00E5B8) : status == 'rejected' ? const Color(0xFFFF3B5C) : const Color(0xFFFFB020);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withAlpha(80))),
      child: Text(status == 'approved' ? 'مقبول' : status == 'rejected' ? 'مرفوض' : 'معلق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent();
  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  final _kmCtrl = TextEditingController();
  final _minCtrl = TextEditingController();
  final _baseCtrl = TextEditingController();
  final _commCtrl = TextEditingController();

  @override
  void dispose() {
    _kmCtrl.dispose(); _minCtrl.dispose(); _baseCtrl.dispose(); _commCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التطبيق'), backgroundColor: const Color(0xFF080D18)),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          final s = state.appSettings;
          if (s != null && _kmCtrl.text.isEmpty) {
            _kmCtrl.text = '${s['pricing_per_km'] ?? 3.5}';
            _minCtrl.text = '${s['pricing_per_min'] ?? 0.5}';
            _baseCtrl.text = '${s['base_fare'] ?? 5.0}';
            _commCtrl.text = '${(s['commission_rate'] ?? 0.15) * 100}';
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إعدادات التسعير', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 20),
                _SettingField(label: 'سعر الكيلومتر (ج.م)', controller: _kmCtrl),
                _SettingField(label: 'سعر الدقيقة (ج.م)', controller: _minCtrl),
                _SettingField(label: 'الأساسي (ج.م)', controller: _baseCtrl),
                _SettingField(label: 'نسبة العمولة (%)', controller: _commCtrl),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    context.read<AdminBloc>().add(UpdateAppSettings({
                      'pricing_per_km': double.tryParse(_kmCtrl.text) ?? 3.5,
                      'pricing_per_min': double.tryParse(_minCtrl.text) ?? 0.5,
                      'base_fare': double.tryParse(_baseCtrl.text) ?? 5.0,
                      'commission_rate': (double.tryParse(_commCtrl.text) ?? 15) / 100,
                    }));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5B8), foregroundColor: const Color(0xFF080D18),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('حفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SettingField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _SettingField({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SizedBox(
        width: 300,
        child: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFFEDF2FC)),
          decoration: InputDecoration(
            labelText: label, labelStyle: const TextStyle(color: Color(0xFF526480)),
            filled: true, fillColor: const Color(0xFF0F1628),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1C2B45))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00E5B8))),
          ),
        ),
      ),
    );
  }
}

class _DataTableWidget extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  const _DataTableWidget({required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFF0F1628), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF1C2B45))),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFF080D18)),
            dataRowColor: WidgetStateProperty.all(Colors.transparent),
            columns: columns.map((c) => DataColumn(label: Text(c, style: const TextStyle(color: Color(0xFF00E5B8), fontWeight: FontWeight.w700, fontSize: 13)))).toList(),
            rows: rows.map((r) => DataRow(cells: r.map((c) => DataCell(Text(c, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 13)))).toList())).toList(),
          ),
        ),
      ),
    );
  }
}

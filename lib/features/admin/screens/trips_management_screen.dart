import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class TripsManagementScreen extends StatefulWidget {
  const TripsManagementScreen({super.key});

  @override
  State<TripsManagementScreen> createState() => _TripsManagementScreenState();
}

class _TripsManagementScreenState extends State<TripsManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadTrips());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('إدارة الرحلات')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          final filtered = state.trips.where((t) {
            final status = (t['status'] as String? ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return _searchQuery.isEmpty || status.contains(q);
          }).toList();
          if (filtered.isEmpty && !state.isLoading) {
            return const Center(
              child: Text('لا توجد رحلات', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'بحث عن رحلة...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.meterMuted),
                      filled: true,
                      fillColor: AppTheme.bgDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      hintStyle: const TextStyle(color: AppTheme.meterMuted),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                );
              }
              final trip = filtered[index - 1] as Map<String, dynamic>;
              final status = trip['status'] as String? ?? '';
              final statusColor = status == 'completed'
                  ? AppTheme.success
                  : status == 'active'
                      ? AppTheme.warning
                      : AppTheme.error;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.meterCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(status,
                          style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (trip['fare'] != null)
                            Text(formatCurrency((trip['fare'] as num).toDouble()),
                                style: const TextStyle(
                                  color: AppTheme.fareNeon,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                )),
                          Text(timeAgo(DateTime.parse(trip['created_at'] as String)),
                              style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
                        ],
                      ),
                    ),
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

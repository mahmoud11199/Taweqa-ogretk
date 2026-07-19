import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class PassengersManagementScreen extends StatefulWidget {
  const PassengersManagementScreen({super.key});

  @override
  State<PassengersManagementScreen> createState() => _PassengersManagementScreenState();
}

class _PassengersManagementScreenState extends State<PassengersManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadPassengers());
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
      appBar: AppBar(title: const Text('إدارة الركاب')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          final filtered = state.passengers.where((p) {
            final name = (p['full_name'] as String? ?? '').toLowerCase();
            final phone = (p['phone'] as String? ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return _searchQuery.isEmpty || name.contains(q) || phone.contains(q);
          }).toList();
          if (filtered.isEmpty && !state.isLoading) {
            return const Center(
              child: Text('لا يوجد ركاب', style: TextStyle(color: AppTheme.meterMuted)),
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
                      hintText: 'بحث عن راكب...',
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
              final p = filtered[index - 1] as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.meterCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['full_name'] as String? ?? '',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text(p['phone'] as String? ?? '',
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

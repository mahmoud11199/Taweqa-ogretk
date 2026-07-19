import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class DriversManagementScreen extends StatefulWidget {
  const DriversManagementScreen({super.key});

  @override
  State<DriversManagementScreen> createState() => _DriversManagementScreenState();
}

class _DriversManagementScreenState extends State<DriversManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadDrivers());
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
      appBar: AppBar(title: const Text('إدارة السائقين')),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          final filtered = state.drivers.where((d) =>
              _searchQuery.isEmpty ||
              d.fullName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          if (filtered.isEmpty && !state.isLoading) {
            return const Center(
              child: Text('لا يوجد سائقين', style: TextStyle(color: AppTheme.meterMuted)),
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
                      hintText: 'بحث عن سائق...',
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
              final driver = filtered[index - 1];
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
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: driver.isAvailable ? AppTheme.success : AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driver.fullName,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          if (driver.carModel != null)
                            Text('${driver.carModel} - ${driver.carPlate ?? ""}',
                                style: const TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(driver.driverType ?? '',
                        style: const TextStyle(color: AppTheme.meterPrimary, fontSize: 12)),
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

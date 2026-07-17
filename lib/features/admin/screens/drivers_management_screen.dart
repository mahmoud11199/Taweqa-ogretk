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
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadDrivers());
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
          if (state.drivers.isEmpty) {
            return const Center(
              child: Text('لا يوجد سائقين', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.drivers.length,
            itemBuilder: (context, index) {
              final driver = state.drivers[index];
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

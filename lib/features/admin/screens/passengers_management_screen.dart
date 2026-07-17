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
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadPassengers());
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
          if (state.passengers.isEmpty) {
            return const Center(
              child: Text('لا يوجد ركاب', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.passengers.length,
            itemBuilder: (context, index) {
              final p = state.passengers[index] as Map<String, dynamic>;
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

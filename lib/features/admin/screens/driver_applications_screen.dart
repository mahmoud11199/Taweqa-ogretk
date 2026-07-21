import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class DriverApplicationsScreen extends StatefulWidget {
  const DriverApplicationsScreen({super.key});

  @override
  State<DriverApplicationsScreen> createState() => _DriverApplicationsScreenState();
}

class _DriverApplicationsScreenState extends State<DriverApplicationsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadDriverApplications());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('طلبات التسجيل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          if (state.driverApplications.isEmpty) return const Center(child: Text('لا توجد طلبات', style: TextStyle(color: Color(0xFF526480))));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.driverApplications.length,
            itemBuilder: (context, index) {
              final app = state.driverApplications[index];
              final isPending = app.status == 'pending';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: const Color(0xFF0F1628), border: Border.all(color: const Color(0xFF1C2B45)), borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPending ? const Color.fromRGBO(255, 176, 32, 0.15) : const Color.fromRGBO(82, 100, 128, 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isPending ? 'معلق' : app.status, style: TextStyle(color: isPending ? const Color(0xFFFFB020) : const Color(0xFF526480), fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(app.fullName, style: const TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w600)),
                    if (app.phone != null) Text(app.phone!, style: const TextStyle(color: Color(0xFF526480), fontSize: 13)),
                    const SizedBox(height: 12),
                    if (app.payload['fields'] != null) ...[
                      const Text('البيانات:', style: TextStyle(color: Color(0xFF00E5B8), fontSize: 12)),
                      const SizedBox(height: 4),
                      ...((app.payload['fields'] as Map<String, dynamic>?) ?? {}).entries.map((e) =>
                        Padding(padding: const EdgeInsets.only(top: 2), child: Text('${e.key}: ${e.value}', style: const TextStyle(color: Color(0xFF526480), fontSize: 12))),
                      ),
                    ],
                    if (isPending) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: SizedBox(height: 40, child: ElevatedButton(
                            onPressed: () => context.read<AdminBloc>().add(ApproveDriver(app.userId)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5B8), foregroundColor: const Color(0xFF080D18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('قبول', style: TextStyle(fontWeight: FontWeight.w700)),
                          ))),
                          const SizedBox(width: 8),
                          Expanded(child: SizedBox(height: 40, child: ElevatedButton(
                            onPressed: () => context.read<AdminBloc>().add(RejectDriver(app.userId)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B5C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('رفض', style: TextStyle(fontWeight: FontWeight.w700)),
                          ))),
                        ],
                      ),
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

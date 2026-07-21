import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('إدارة الرحلات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final filtered = state.trips.where((t) {
            final status = (t['status'] as String? ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return _searchQuery.isEmpty || status.contains(q);
          }).toList();
          if (filtered.isEmpty && !state.isLoading) return const Center(child: Text('لا توجد رحلات', style: TextStyle(color: Color(0xFF526480))));
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: filtered.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Color(0xFFEDF2FC)),
                    decoration: const InputDecoration(
                      hintText: 'بحث عن رحلة...', hintStyle: TextStyle(color: Color(0xFF526480)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF526480)),
                      filled: true, fillColor: Color(0xFF0F1628),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                );
              }
              final trip = filtered[index - 1] as Map<String, dynamic>;
              final status = trip['status'] as String? ?? '';
              final statusColor = status == 'completed' ? const Color(0xFF00E5B8) : status == 'active' ? const Color(0xFFFFB020) : const Color(0xFFFF3B5C);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0F1628), border: Border.all(color: const Color(0xFF1C2B45)), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                      child: Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (trip['fare'] != null) Text(formatCurrency((trip['fare'] as num).toDouble()), style: const TextStyle(color: Color(0xFF00E5B8), fontWeight: FontWeight.w900, fontSize: 15)),
                        Text(timeAgo(DateTime.parse(trip['created_at'] as String)), style: const TextStyle(color: Color(0xFF526480), fontSize: 12)),
                      ],
                    )),
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

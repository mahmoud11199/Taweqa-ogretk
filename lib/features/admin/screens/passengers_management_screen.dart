import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('إدارة الركاب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final filtered = state.passengers.where((p) {
            final name = (p['full_name'] as String? ?? '').toLowerCase();
            final phone = (p['phone'] as String? ?? '').toLowerCase();
            final q = _searchQuery.toLowerCase();
            return _searchQuery.isEmpty || name.contains(q) || phone.contains(q);
          }).toList();
          if (filtered.isEmpty && !state.isLoading) return const Center(child: Text('لا يوجد ركاب', style: TextStyle(color: Color(0xFF526480))));
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
                      hintText: 'بحث عن راكب...', hintStyle: TextStyle(color: Color(0xFF526480)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF526480)),
                      filled: true, fillColor: Color(0xFF0F1628),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                );
              }
              final p = filtered[index - 1] as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0F1628), border: Border.all(color: const Color(0xFF1C2B45)), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 20, backgroundColor: Color(0xFF1C2B45), child: Icon(Icons.person, color: Color(0xFF526480))),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p['full_name'] as String? ?? '', style: const TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w600)),
                        Text(p['phone'] as String? ?? '', style: const TextStyle(color: Color(0xFF526480), fontSize: 12)),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('إدارة السائقين', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final filtered = state.drivers.where((d) => _searchQuery.isEmpty || d.fullName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          if (filtered.isEmpty && !state.isLoading) return const Center(child: Text('لا يوجد سائقين', style: TextStyle(color: Color(0xFF526480))));
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
                      hintText: 'بحث عن سائق...', hintStyle: TextStyle(color: Color(0xFF526480)),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF526480)),
                      filled: true, fillColor: Color(0xFF0F1628),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                );
              }
              final driver = filtered[index - 1];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFF0F1628), border: Border.all(color: const Color(0xFF1C2B45)), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: driver.isAvailable ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.fullName, style: const TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w600)),
                        if (driver.carModel != null) Text('${driver.carModel} - ${driver.carPlate ?? ""}', style: const TextStyle(color: Color(0xFF526480), fontSize: 12)),
                      ],
                    )),
                    Text(driver.driverType ?? '', style: const TextStyle(color: Color(0xFF00E5B8), fontSize: 12)),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => context.read<AdminBloc>().add(ToggleDriverBan(userId: driver.id, banned: !driver.banned)),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: driver.banned ? const Color.fromRGBO(255, 59, 92, 0.15) : const Color.fromRGBO(0, 229, 184, 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(driver.banned ? 'محظور' : 'نشط', style: TextStyle(color: driver.banned ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8), fontSize: 11, fontWeight: FontWeight.w700)),
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

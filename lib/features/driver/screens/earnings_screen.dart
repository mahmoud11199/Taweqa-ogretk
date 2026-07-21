import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/driver_bloc.dart';
import '../bloc/driver_event.dart';
import '../bloc/driver_state.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DriverBloc>().add(FetchEarnings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('الأرباح', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<DriverBloc, DriverState>(
        builder: (context, state) {
          if (state.isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          final earnings = state.earnings;
          if (earnings == null) return const Center(child: Text('لا توجد أرباح بعد', style: TextStyle(color: Color(0xFF526480), fontSize: 16)));
          final totalFare = (earnings['total_fare'] as num?)?.toDouble() ?? 0;
          final totalCut = (earnings['total_cut'] as num?)?.toDouble() ?? 0;
          final count = (earnings['count'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF001A14), Color(0xFF002E22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      const Text('إجمالي الأرباح', style: TextStyle(color: Color(0xFF526480), fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(formatCurrency(totalCut), style: const TextStyle(fontFamily: 'monospace', color: Color(0xFF00E5B8), fontSize: 36, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text('(${formatCurrency(totalFare)} إجمالي الأجرة)', style: const TextStyle(color: Color(0xFF3A5070), fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _EStatCard(icon: Icons.route_outlined, label: 'عدد الرحلات', value: '$count')),
                    const SizedBox(width: 12),
                    Expanded(child: _EStatCard(icon: Icons.trending_up, label: 'متوسط الرحلة', value: count > 0 ? formatCurrency(totalCut / count) : '0 ج')),
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

class _EStatCard extends StatelessWidget {
  final IconData icon; final String label; final String value;
  const _EStatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00E5B8), size: 28),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontFamily: 'monospace', color: Color(0xFFEDF2FC), fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF526480), fontSize: 13)),
        ],
      ),
    );
  }
}

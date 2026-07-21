import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  final _perKmController = TextEditingController();
  final _perMinController = TextEditingController();
  final _baseFareController = TextEditingController();
  final _commissionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(LoadAppSettings());
  }

  @override
  void dispose() {
    _perKmController.dispose();
    _perMinController.dispose();
    _baseFareController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  void _loadSettings(Map<String, double>? settings) {
    if (settings == null) return;
    _perKmController.text = (settings['pricing_per_km'] ?? 3.5).toString();
    _perMinController.text = (settings['pricing_per_min'] ?? 0.5).toString();
    _baseFareController.text = (settings['base_fare'] ?? 5.0).toString();
    _commissionController.text = ((settings['commission_rate'] ?? 0.15) * 100).toStringAsFixed(1);
  }

  void _save() {
    final perKm = double.tryParse(_perKmController.text);
    final perMin = double.tryParse(_perMinController.text);
    final baseFare = double.tryParse(_baseFareController.text);
    final commission = double.tryParse(_commissionController.text);
    if (perKm == null || perMin == null || baseFare == null || commission == null) {
      showToast(context, 'يرجى إدخال أرقام صحيحة', isError: true);
      return;
    }
    context.read<AdminBloc>().add(UpdateAppSettings({
      'pricing_per_km': perKm, 'pricing_per_min': perMin,
      'base_fare': baseFare, 'commission_rate': commission / 100,
    }));
    showToast(context, 'تم حفظ الإعدادات');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text('إعدادات التطبيق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))), centerTitle: true, leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context))),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state.isLoading && state.appSettings == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          if (state.appSettings != null && _perKmController.text.isEmpty) _loadSettings(state.appSettings);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Field(label: 'سعر الكيلومتر (جنيه)', controller: _perKmController),
                const SizedBox(height: 16),
                _Field(label: 'سعر الدقيقة (جنيه)', controller: _perMinController),
                const SizedBox(height: 16),
                _Field(label: 'الأساسي (جنيه)', controller: _baseFareController),
                const SizedBox(height: 16),
                _Field(label: 'نسبة التطبيق (%)', controller: _commissionController),
                const SizedBox(height: 32),
                SizedBox(height: 52, child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5B8), foregroundColor: const Color(0xFF080D18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _Field({required this.label, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF526480)),
        filled: true, fillColor: const Color(0xFF0F1628),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1C2B45))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF00E5B8))),
      ),
      style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 16),
    );
  }
}

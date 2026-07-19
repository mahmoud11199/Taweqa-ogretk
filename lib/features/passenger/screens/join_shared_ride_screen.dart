import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/passenger_bloc.dart';
import '../bloc/passenger_event.dart';
import '../bloc/passenger_state.dart';

class JoinSharedRideScreen extends StatefulWidget {
  const JoinSharedRideScreen({super.key});

  @override
  State<JoinSharedRideScreen> createState() => _JoinSharedRideScreenState();
}

class _JoinSharedRideScreenState extends State<JoinSharedRideScreen> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _join() {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      showToast(context, 'يرجى إدخال كود المشاركة', isError: true);
      return;
    }
    final state = context.read<PassengerBloc>().state;
    if (state.pickupLat == null) {
      showToast(context, 'يرجى تحديد موقع الالتقاط أولاً', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(JoinSharedRide(
      shareCode: code,
      pickupLat: state.pickupLat!,
      pickupLng: state.pickupLng!,
      pickupAddress: state.pickupAddress,
      destLat: state.destLat,
      destLng: state.destLng,
      destAddress: state.destAddress,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('انضمام لرحلة تشاركية'),
        backgroundColor: AppTheme.meterCard,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.group_add, size: 64, color: AppTheme.meterPrimary),
            const SizedBox(height: 16),
            const Text(
              'أدخل كود المشاركة المكون من 6 أرقام',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 8,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: AppTheme.meterMuted.withValues(alpha: 0.4), fontSize: 24),
                filled: true,
                fillColor: AppTheme.meterCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<PassengerBloc, PassengerState>(
              builder: (context, state) {
                if (state.joinedTripId != null) {
                  return Column(
                    children: [
                      const Icon(Icons.check_circle, size: 48, color: AppTheme.success),
                      const SizedBox(height: 8),
                      const Text('تم الانضمام للرحلة بنجاح!', style: TextStyle(color: AppTheme.success, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success),
                        child: const Text('العودة'),
                      ),
                    ],
                  );
                }
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.meterPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: state.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('انضمام', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

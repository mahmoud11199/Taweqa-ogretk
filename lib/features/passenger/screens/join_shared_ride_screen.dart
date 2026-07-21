import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final s = context.read<PassengerBloc>().state;
    if (s.pickupLat == null) {
      showToast(context, 'يرجى تحديد موقع الالتقاط أولاً', isError: true);
      return;
    }
    context.read<PassengerBloc>().add(JoinSharedRide(
      shareCode: code, pickupLat: s.pickupLat!, pickupLng: s.pickupLng!,
      pickupAddress: s.pickupAddress, destLat: s.destLat,
      destLng: s.destLng, destAddress: s.destAddress,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('انضمام لرحلة تشاركية', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.group_add, size: 40, color: Color(0xFF080D18)),
            ),
            const SizedBox(height: 20),
            const Text(
              'أدخل كود المشاركة المكون من 6 أرقام',
              style: TextStyle(fontSize: 16, color: Color(0xFFEDF2FC)),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _codeController,
              textAlign: TextAlign.center,
              maxLength: 6,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '000000',
                hintStyle: TextStyle(color: Color.fromRGBO(82, 100, 128, 0.4), fontSize: 24),
                filled: true,
                fillColor: Color(0xFF0F1628),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF1C2B45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF1C2B45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(14)),
                  borderSide: BorderSide(color: Color(0xFF00E5B8)),
                ),
                counterText: '',
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
            BlocBuilder<PassengerBloc, PassengerState>(
              builder: (context, state) {
                if (state.joinedTripId != null) {
                  return Column(
                    children: [
                      const Icon(Icons.check_circle, size: 48, color: Color(0xFF00E5B8)),
                      const SizedBox(height: 8),
                      const Text('تم الانضمام للرحلة بنجاح!', style: TextStyle(color: Color(0xFF00E5B8), fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5B8),
                          foregroundColor: const Color(0xFF080D18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        child: const Text('العودة', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  );
                }
                return SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _join,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00E5B8),
                      foregroundColor: const Color(0xFF080D18),
                      disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: state.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                        : const Text('انضمام', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

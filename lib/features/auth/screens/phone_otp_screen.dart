import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'register_screen.dart';

class PhoneOtpScreen extends StatefulWidget {
  final String phone;
  const PhoneOtpScreen({super.key, required this.phone});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  final _otpCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('رمز التحقق'), backgroundColor: AppTheme.meterBg),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PhoneOtpVerified) {
            // Try to fetch profile — if exists, login; else navigate to register
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: AppTheme.error));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(color: AppTheme.success.withAlpha(25), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.sms, size: 36, color: AppTheme.success),
                ),
                const SizedBox(height: 24),
                const Text('أدخل رمز التحقق', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text('تم إرسال الرمز إلى ${widget.phone}', style: const TextStyle(fontSize: 14, color: AppTheme.meterMuted)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, letterSpacing: 8, fontWeight: FontWeight.w700, color: Colors.white),
                  validator: (v) {
                    if (v == null || v.length < 4) return 'يرجى إدخال رمز التحقق';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'رمز التحقق',
                    hintText: '000000',
                    counterText: '',
                    prefixIcon: Icon(Icons.lock, color: AppTheme.meterPrimary),
                  ),
                ),
                const SizedBox(height: 32),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthBloc>().add(VerifyPhoneOtp(phone: widget.phone, otp: _otpCtrl.text));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.meterPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('تأكيد', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.read<AuthBloc>().add(SendPhoneOtp(phone: widget.phone)),
                    child: const Text('إعادة إرسال الرمز', style: TextStyle(color: AppTheme.meterPrimary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

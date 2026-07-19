import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'phone_otp_screen.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneCtrl = TextEditingController(text: '+20');
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('تسجيل الدخول بالهاتف'), backgroundColor: AppTheme.meterBg),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PhoneOtpSent) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PhoneOtpScreen(phone: state.phone)));
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
                  decoration: BoxDecoration(color: AppTheme.meterPrimary.withAlpha(25), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.phone_android, size: 36, color: AppTheme.meterPrimary),
                ),
                const SizedBox(height: 24),
                const Text('أدخل رقم هاتفك', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                const Text('سوف نرسل لك رمز تحقق عبر WhatsApp أو SMS', style: TextStyle(fontSize: 14, color: AppTheme.meterMuted)),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.length < 10) return 'يرجى إدخال رقم هاتف صحيح';
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف',
                    hintText: '+20xxxxxxxxxx',
                    prefixIcon: Icon(Icons.phone, color: AppTheme.meterPrimary),
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
                            context.read<AuthBloc>().add(SendPhoneOtp(phone: _phoneCtrl.text));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.meterPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: loading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('إرسال رمز التحقق', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

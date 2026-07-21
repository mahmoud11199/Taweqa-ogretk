import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(ForgotPasswordRequested(email: _emailController.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) showToast(context, state.message, isError: true);
        if (state is PasswordResetSent) {
          showToast(context, state.message);
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 800), () { if (mounted) navigator.pop(); });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إعادة تعيين كلمة السر', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 229, 184, 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_reset, size: 36, color: Color(0xFF00E5B8)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'أدخل بريدك الإلكتروني وسنرسل لك رابط إعادة تعيين كلمة السر',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Color(0xFF526480)),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      labelStyle: TextStyle(color: Color(0xFF526480)),
                      prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF526480)),
                      filled: true,
                      fillColor: Color(0xFF0F1628),
                      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF00E5B8))),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) { if (v == null || v.isEmpty) return 'يرجى إدخال البريد'; return null; },
                    onFieldSubmitted: (_) => _handleReset(),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5B8),
                            foregroundColor: const Color(0xFF080D18),
                            disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                              : const Text('إرسال رابط إعادة التعيين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

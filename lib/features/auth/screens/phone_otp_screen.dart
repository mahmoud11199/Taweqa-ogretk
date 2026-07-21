import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secs = 59;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secs <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secs--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChange(int i, String v) {
    if (v.length > 1) return;
    final digit = v.isEmpty ? '' : v[v.length - 1];
    if (digit.isNotEmpty && !RegExp(r'^\d$').hasMatch(digit)) return;

    _controllers[i].text = digit;
    _controllers[i].selection = TextSelection.collapsed(offset: digit.length);

    if (digit.isNotEmpty && i < 5) {
      _focusNodes[i + 1].requestFocus();
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();
  bool get _allFilled => _otp.length == 6 && _otp.split('').every((d) => d.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFEDF2FC)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Verify Phone', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PhoneOtpVerified) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => RegisterScreen(phone: widget.phone)),
            );
          } else if (state is AuthAuthenticated) {
            final p = state.profile;
            final route = p.isAdmin ? '/admin' : p.isDriver ? '/driver' : '/passenger';
            Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: const Color(0xFFFF3B5C)),
            );
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 32),
                // Illustration
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F1628),
                          border: Border.all(color: const Color(0xFF1C2B45)),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Center(child: Text('📱', style: TextStyle(fontSize: 40))),
                      ),
                      const SizedBox(height: 20),
                      const Text('Enter your code', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          text: 'We sent a 6-digit code to\n',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF526480), height: 1.7),
                          children: [
                            TextSpan(
                              text: widget.phone,
                              style: const TextStyle(color: Color(0xFF00E5B8), fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // OTP boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Padding(
                      padding: EdgeInsets.only(left: i > 0 ? 9 : 0),
                      child: SizedBox(
                        width: 50,
                        height: 60,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEDF2FC),
                            fontFamily: 'monospace',
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: _controllers[i].text.isNotEmpty
                                ? const Color(0xFF152038)
                                : const Color(0xFF0C1220),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _controllers[i].text.isNotEmpty
                                    ? const Color(0xFF00E5B8)
                                    : const Color(0xFF1C2B45),
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: _controllers[i].text.isNotEmpty
                                    ? const Color(0xFF00E5B8)
                                    : const Color(0xFF1C2B45),
                                width: 2,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF00E5B8), width: 2),
                            ),
                          ),
                          onChanged: (v) => _onDigitChange(i, v),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),
                // Countdown
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        children: [
                          const CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 3,
                            color: Color(0xFF1C2B45),
                            backgroundColor: Colors.transparent,
                          ),
                          CircularProgressIndicator(
                            value: _secs / 59.0,
                            strokeWidth: 3,
                            color: _secs < 15 ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8),
                            backgroundColor: Colors.transparent,
                            strokeCap: StrokeCap.round,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '0:${_secs.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'monospace',
                            color: _secs < 15 ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8),
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text('before expiry', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Verify button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (!_allFilled || loading) ? null : () {
                          context.read<AuthBloc>().add(VerifyPhoneOtp(phone: widget.phone, otp: _otp));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5B8),
                          foregroundColor: const Color(0xFF080D18),
                          disabledBackgroundColor: const Color(0xFF1C2B45),
                          disabledForegroundColor: const Color(0xFF526480),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                            : const Text('Verify & Continue'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Resend
                Center(
                  child: TextButton(
                    onPressed: _secs == 0
                        ? () {
                            setState(() {
                              _secs = 59;
                              _startCountdown();
                            });
                            context.read<AuthBloc>().add(SendPhoneOtp(phone: widget.phone));
                          }
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 13,
                          color: _secs == 0 ? const Color(0xFF00E5B8) : const Color(0xFF526480),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Resend code',
                          style: TextStyle(
                            fontSize: 13,
                            color: _secs == 0 ? const Color(0xFF00E5B8) : const Color(0xFF526480),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Security note
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 229, 184, 0.04),
                    border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.13)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.shield, size: 15, color: Color(0xFF00E5B8)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Adady Maren will ',
                            style: TextStyle(fontSize: 12, color: Color(0xFF526480), height: 1.6),
                            children: [
                              TextSpan(
                                text: 'never',
                                style: TextStyle(color: Color(0xFF8EA4C8)),
                              ),
                              TextSpan(
                                text: ' ask for your OTP. Keep it private.',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

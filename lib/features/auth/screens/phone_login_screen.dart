import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int _tab = 0; // 0 = phone, 1 = email
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_tab == 0) {
      final phone = _phoneCtrl.text.trim();
      if (phone.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال رقم هاتف صحيح'), backgroundColor: Color(0xFFFF3B5C)),
        );
        return;
      }
      context.read<AuthBloc>().add(SendPhoneOtp(phone: phone));
    } else {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      if (email.isEmpty || password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى إدخال البريد وكلمة السر'), backgroundColor: Color(0xFFFF3B5C)),
        );
        return;
      }
      context.read<AuthBloc>().add(LoginRequested(email: email, password: password));
    }
  }

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
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is PhoneOtpSent) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => PhoneOtpScreen(phone: state.phone)));
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
                const SizedBox(height: 20),
                // Logo
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment(0.77, -0.64),
                            end: Alignment(-0.77, 0.64),
                            colors: [Color(0xFF00E5B8), Color(0xFF0088CC)],
                          ),
                          boxShadow: const [
                            BoxShadow(color: Color.fromRGBO(0, 229, 184, 0.3), blurRadius: 32),
                          ],
                        ),
                        child: const Icon(Icons.navigation, size: 28, color: Color(0xFF050A14)),
                      ),
                      const SizedBox(height: 14),
                      const Text('Sign In', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC), height: 1)),
                      const SizedBox(height: 4),
                      const Text('Welcome back to Adady Maren', style: TextStyle(fontSize: 13, color: Color(0xFF526480))),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
                // Tab switcher
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1220),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['Phone', 'Email'].asMap().entries.map((e) {
                      final i = e.key;
                      final label = e.value;
                      final active = _tab == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF00E5B8) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active ? const Color(0xFF080D18) : const Color(0xFF526480),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
                // Fields
                if (_tab == 0) _buildPhoneField(),
                if (_tab == 1) _buildEmailFields(),
                const SizedBox(height: 24),
                // Continue button
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final loading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: loading ? null : _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E5B8),
                          foregroundColor: const Color(0xFF080D18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        child: loading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                            : Text(_tab == 0 ? 'Send OTP →' : 'Continue →'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // TOS
                const Text.rich(
                  TextSpan(
                    text: 'By continuing you agree to our ',
                    style: TextStyle(fontSize: 12, color: Color(0xFF526480)),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(color: Color(0xFF00E5B8)),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFF1C2B45))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or continue with', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                    ),
                    Expanded(child: Divider(color: Color(0xFF1C2B45))),
                  ],
                ),
                const SizedBox(height: 16),
                // Google button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1220),
                    border: Border.all(color: const Color(0xFF1C2B45)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🌐', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 10),
                      Text('Google', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MOBILE NUMBER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
        const SizedBox(height: 7),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 15, color: Color(0xFFEDF2FC)),
          decoration: InputDecoration(
            hintText: '010 XXXX XXXX',
            hintStyle: const TextStyle(color: Color(0xFF526480)),
            filled: true,
            fillColor: const Color(0xFF0C1220),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1C2B45)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF1C2B45)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00E5B8), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 14, right: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🇪🇬', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text('+20', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF8EA4C8))),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 72, minHeight: 0),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailFields() {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('EMAIL ADDRESS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
            const SizedBox(height: 7),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 15, color: Color(0xFFEDF2FC)),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                hintStyle: const TextStyle(color: Color(0xFF526480)),
                filled: true,
                fillColor: const Color(0xFF0C1220),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2B45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2B45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00E5B8), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.mail_outline, size: 16, color: Color(0xFF526480)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
            const SizedBox(height: 7),
            TextField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              style: const TextStyle(fontSize: 15, color: Color(0xFFEDF2FC)),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFF526480)),
                filled: true,
                fillColor: const Color(0xFF0C1220),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2B45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1C2B45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00E5B8), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14),
                  child: Icon(Icons.lock_outline, size: 16, color: Color(0xFF526480)),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 16,
                    color: const Color(0xFF526480),
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

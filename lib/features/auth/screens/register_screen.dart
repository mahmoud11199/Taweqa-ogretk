import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../models/user_model.dart';
import '../widgets/role_selector.dart';
import '../widgets/driver_field.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? phone;
  const RegisterScreen({super.key, this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _refCodeController = TextEditingController();
  String _selectedRole = 'passenger';
  DriverType? _selectedDriverType;
  final Map<String, dynamic> _driverFields = {};
  final Map<String, dynamic> _driverFiles = {};
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    if (widget.phone != null) _phoneController.text = widget.phone!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _refCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRole == 'driver') {
      final required = ['car_model', 'car_plate', 'car_color'];
      for (final field in required) {
        if (((_driverFields[field] as String?)?.isEmpty ?? true) && (_driverFiles[field] == null)) {
          showToast(context, 'يرجى إكمال جميع الحقول المطلوبة للسائق', isError: true);
          return;
        }
      }
    }
    context.read<AuthBloc>().add(RegisterRequested(
      name: _nameController.text.trim(), email: _emailController.text.trim(),
      phone: _phoneController.text.trim(), password: _passwordController.text,
      role: _selectedRole, refCode: _refCodeController.text.trim().isEmpty ? null : _refCodeController.text.trim(),
      driverType: _selectedRole == 'driver' ? _selectedDriverType : null,
      driverFields: _driverFields, driverFiles: _driverFiles.map((k, v) => MapEntry(k, v as File?)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) showToast(context, state.message, isError: true);
        if (state is AuthAuthenticated) {
          final p = state.profile;
          final route = p.isAdmin ? '/admin' : p.isDriver ? '/driver' : '/passenger';
          Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF080D18),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إنشاء حساب جديد', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildField(label: 'الاسم بالكامل', icon: Icons.person_outlined, controller: _nameController, validator: Validators.name),
                  const SizedBox(height: 14),
                  _buildField(label: 'البريد الإلكتروني', icon: Icons.email_outlined, controller: _emailController, keyboardType: TextInputType.emailAddress, validator: Validators.email),
                  const SizedBox(height: 14),
                  _buildField(label: 'رقم الهاتف', icon: Icons.phone_outlined, controller: _phoneController, keyboardType: TextInputType.phone, validator: Validators.phone),
                  const SizedBox(height: 14),
                  _buildPasswordField(label: 'كلمة السر', controller: _passwordController, obscure: _obscurePassword, toggle: () => setState(() => _obscurePassword = !_obscurePassword), validator: Validators.password),
                  const SizedBox(height: 6),
                  _PasswordStrengthBar(password: _passwordController.text, controller: _passwordController),
                  const SizedBox(height: 8),
                  _buildPasswordField(label: 'تأكيد كلمة السر', controller: _confirmPasswordController, obscure: _obscureConfirm, toggle: () => setState(() => _obscureConfirm = !_obscureConfirm), validator: (v) => Validators.confirmPassword(v, _passwordController.text)),
                  const SizedBox(height: 14),
                  _buildField(label: 'كود الإحالة (اختياري)', icon: Icons.discount_outlined, controller: _refCodeController),
                  const SizedBox(height: 20),
                  const Text('اختر نوع الحساب', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF526480))),
                  const SizedBox(height: 10),
                  RoleSelector(
                    selectedRole: _selectedRole, selectedDriverType: _selectedDriverType,
                    onRoleChanged: (role) => setState(() => _selectedRole = role),
                    onDriverTypeChanged: (type) => setState(() => _selectedDriverType = type),
                  ),
                  if (_selectedRole == 'driver') ...[
                    const SizedBox(height: 16),
                    DriverField(
                      onFieldsChanged: (fields) => _driverFields..clear()..addAll(fields),
                      onFilesChanged: (files) => setState(() { _driverFiles.addAll(files); }),
                    ),
                  ],
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity, height: 52,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00E5B8),
                            foregroundColor: const Color(0xFF080D18),
                            disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                              : const Text('إنشاء الحساب', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: const Text('لديك حساب بالفعل؟ سجل دخول', style: TextStyle(color: Color(0xFF00E5B8))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({required String label, required IconData icon, required TextEditingController controller, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF526480)),
        prefixIcon: Icon(icon, color: const Color(0xFF526480)),
        filled: true, fillColor: const Color(0xFF0F1628),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF00E5B8))),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildPasswordField({required String label, required TextEditingController controller, required bool obscure, required VoidCallback toggle, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
      decoration: InputDecoration(
        labelText: label, labelStyle: const TextStyle(color: Color(0xFF526480)),
        prefixIcon: const Icon(Icons.lock_outlined, color: Color(0xFF526480)),
        suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF526480)), onPressed: toggle),
        filled: true, fillColor: const Color(0xFF0F1628),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF1C2B45))),
        focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide(color: Color(0xFF00E5B8))),
      ),
      obscureText: obscure,
      validator: validator,
    );
  }
}

// ─── Password Strength Bar ──────────────────────────────────────────────────
class _PasswordStrengthBar extends StatefulWidget {
  final String password;
  final TextEditingController controller;
  const _PasswordStrengthBar({required this.password, required this.controller});

  @override
  State<_PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<_PasswordStrengthBar> {
  String _pwd = '';

  @override
  void initState() {
    super.initState();
    _pwd = widget.password;
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_PasswordStrengthBar old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() => _pwd = widget.controller.text);

  @override
  Widget build(BuildContext context) {
    if (_pwd.isEmpty) return const SizedBox.shrink();
    return _StrengthBar(password: _pwd);
  }
}

class _StrengthBar extends StatelessWidget {
  final String password;
  const _StrengthBar({required this.password});

  (double, Color, String) _strength() {
    if (password.length < 4) return (0.2, const Color(0xFFFF3B5C), 'ضعيفة');
    if (password.length < 6) return (0.35, const Color(0xFFFF6B35), 'ضعيفة');
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
    int score = 0;
    if (password.length >= 8) score++;
    if (hasUpper) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;
    if (score <= 1) return (0.5, const Color(0xFFFFB020), 'متوسطة');
    if (score == 2) return (0.7, const Color(0xFF8BC34A), 'جيدة');
    return (1.0, const Color(0xFF00E5B8), 'قوية');
  }

  @override
  Widget build(BuildContext context) {
    final (fraction, color, label) = _strength();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction, backgroundColor: const Color(0xFF1C2B45),
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

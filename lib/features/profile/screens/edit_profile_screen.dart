import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _email = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final metadata = user.userMetadata;
    _nameController.text = metadata?['name'] as String? ?? '';
    _phoneController.text = metadata?['phone'] as String? ?? '';
    _email = user.email ?? '';
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final name = _nameController.text.trim();
      final phone = _phoneController.text.trim();

      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(data: {'name': name, 'phone': phone}),
      );

      await SupabaseConfig.client.from('profiles').update({
        'full_name': name,
        'phone': phone,
      }).eq('id', user.id);

      if (mounted) showToast(context, 'تم حفظ التغييرات بنجاح');
    } catch (e) {
      if (mounted) showToast(context, 'حدث خطأ أثناء الحفظ', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('تعديل الملف الشخصي')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.meterCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(Icons.person, size: 64, color: AppTheme.meterPrimary),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isEmpty ? 'مستخدم' : _nameController.text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _email,
                    style: const TextStyle(color: AppTheme.meterMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'الاسم الكامل',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'أدخل اسمك الكامل'),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            const Text(
              'رقم الهاتف',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(hintText: 'أدخل رقم الهاتف'),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.meterPrimary,
                  foregroundColor: AppTheme.bgDeep,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.bgDeep),
                      )
                    : const Text('حفظ التغييرات', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

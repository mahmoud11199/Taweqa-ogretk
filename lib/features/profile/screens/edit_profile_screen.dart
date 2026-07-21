import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الملف الشخصي', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1628),
                border: Border.all(color: const Color(0xFF1C2B45)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)]),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.person, size: 36, color: Color(0xFF080D18)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _nameController.text.isEmpty ? 'مستخدم' : _nameController.text,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC)),
                  ),
                  const SizedBox(height: 4),
                  Text(_email, style: const TextStyle(fontSize: 13, color: Color(0xFF526480))),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Name field
            const Text('الاسم الكامل', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8EA4C8))),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'أدخل اسمك الكامل',
                hintStyle: TextStyle(color: Color(0xFF3A5070)),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 18),
            // Phone field
            const Text('رقم الهاتف', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8EA4C8))),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 15),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                hintText: 'أدخل رقم الهاتف',
                hintStyle: TextStyle(color: Color(0xFF3A5070)),
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5B8),
                  foregroundColor: const Color(0xFF080D18),
                  disabledBackgroundColor: const Color.fromRGBO(0, 229, 184, 0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                    : const Text('حفظ التغييرات', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

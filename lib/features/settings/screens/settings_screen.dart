import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/toast_widget.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../profile/screens/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool inTab;
  const SettingsScreen({super.key, this.inTab = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _deleting = false;

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حول التطبيق', style: TextStyle(color: Color(0xFFEDF2FC), fontWeight: FontWeight.w700)),
        content: const Text('تطبيق توقيت – لتجربة نقل ذكية وسلسة.', style: TextStyle(color: Color(0xFF526480), fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً', style: TextStyle(color: Color(0xFF00E5B8))),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    await SupabaseConfig.client.auth.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1628),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف الحساب', style: TextStyle(color: Color(0xFFFF3B5C), fontWeight: FontWeight.w700)),
        content: const Text('هل أنت متأكد؟ سيتم حذف حسابك نهائياً ولا يمكن التراجع عن هذا الإجراء.', style: TextStyle(color: Color(0xFFEDF2FC))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء', style: TextStyle(color: Color(0xFF526480))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Color(0xFFFF3B5C))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) throw Exception('No user');
      final response = await http.post(
        Uri.parse('${AppConstants.supabaseUrl}/functions/v1/delete-user'),
        headers: {
          'Authorization': 'Bearer ${SupabaseConfig.client.auth.currentSession?.accessToken ?? ''}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'user_id': user.id}),
      );
      if (response.statusCode != 200) throw Exception('فشل حذف الحساب');
      await SupabaseConfig.client.auth.signOut();
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    } catch (e) {
      if (mounted) showToast(context, 'فشل حذف الحساب', isError: true);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: widget.inTab ? const SizedBox.shrink() : IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const Text('الحساب', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.4)),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.person, label: 'الملف الشخصي', sub: 'الاسم، رقم الهاتف والبريد',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
          ),
          const SizedBox(height: 20),
          const Text('التطبيق', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.4)),
          const SizedBox(height: 10),
          const _SettingsTile(icon: Icons.info_outline, label: 'الإصدار', trailing: Text('1.0.0', style: TextStyle(color: Color(0xFF3A5070), fontSize: 14))),
          _SettingsTile(icon: Icons.description, label: 'حول التطبيق', onTap: _showAboutDialog),
          const SizedBox(height: 20),
          const Text('الأمان', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.4)),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.logout, label: 'تسجيل الخروج',
            iconColor: const Color(0xFFFFB020),
            onTap: _logout,
          ),
          _SettingsTile(
            icon: Icons.delete_forever, label: 'حذف الحساب', sub: 'نهائياً ولا يمكن التراجع',
            iconColor: const Color(0xFFFF3B5C),
            onTap: _deleting ? null : _deleteAccount,
            trailing: _deleting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF3B5C)))
                : null,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon, required this.label, this.sub,
    this.onTap, this.trailing, this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFF00E5B8)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: iconColor ?? const Color(0xFF00E5B8), size: 19),
        ),
        title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
        subtitle: sub != null ? Text(sub!, style: const TextStyle(fontSize: 11, color: Color(0xFF526480))) : null,
        trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_left, color: Color(0xFF3A5070), size: 18) : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

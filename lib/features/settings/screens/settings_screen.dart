import 'package:flutter/material.dart';
import '../../profile/screens/edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الإعدادات', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
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

  const _SettingsTile({
    required this.icon, required this.label, this.sub,
    this.onTap, this.trailing,
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
            color: const Color.fromRGBO(0, 229, 184, 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: const Color(0xFF00E5B8), size: 19),
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

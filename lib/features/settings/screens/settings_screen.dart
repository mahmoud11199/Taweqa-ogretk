import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
        backgroundColor: AppTheme.meterCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'حول التطبيق',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'تطبيق توقيت – لتجربة نقل ذكية وسلسة.',
          style: TextStyle(color: AppTheme.meterMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('حسناً', style: TextStyle(color: AppTheme.meterPrimary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SettingsTile(
            icon: Icons.person,
            title: 'حسابي',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          const _SettingsTile(
            icon: Icons.info,
            title: 'الإصدار',
            trailing: Text(
              '1.0.0',
              style: TextStyle(color: AppTheme.meterMuted, fontSize: 14),
            ),
          ),
          _SettingsTile(
            icon: Icons.description,
            title: 'حول التطبيق',
            onTap: _showAboutDialog,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.meterCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.meterPrimary, size: 24),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_left, color: AppTheme.meterMuted)
            : null),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class DownloadSection extends StatelessWidget {
  final String? apkUrl;
  final String? iosUrl;

  const DownloadSection({super.key, this.apkUrl, this.iosUrl});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      color: AppTheme.meterCard,
      child: Column(
        children: [
          const Text('حمل التطبيق الآن', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('متوفر لأندرويد و iOS', style: TextStyle(fontSize: 15, color: AppTheme.meterMuted)),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              if (apkUrl != null)
                _StoreButton(
                  icon: Icons.android,
                  label: 'Google Play',
                  onTap: () => launchUrl(Uri.parse(apkUrl!), mode: LaunchMode.externalApplication),
                ),
              if (iosUrl != null)
                _StoreButton(
                  icon: Icons.apple,
                  label: 'App Store',
                  onTap: () => launchUrl(Uri.parse(iosUrl!), mode: LaunchMode.externalApplication),
                ),
              if (apkUrl == null && iosUrl == null) ...[
                const _StoreButton(icon: Icons.android, label: 'Android (قريباً)', onTap: null),
                const _StoreButton(icon: Icons.apple, label: 'iOS (قريباً)', onTap: null),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _StoreButton({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: onTap != null ? AppTheme.meterPrimary : AppTheme.meterCard,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.meterCard,
          disabledForegroundColor: AppTheme.meterMuted,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

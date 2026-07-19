import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureItem({required this.icon, required this.title, required this.description});
}

const List<_FeatureItem> _features = [
  _FeatureItem(
    icon: Icons.calculate_rounded,
    title: 'حاسبة الأجرة الذكية',
    description: 'حساب دقيق للأجرة بناءً على المسافة والوقت وانتظار العملاء.',
  ),
  _FeatureItem(
    icon: Icons.map_rounded,
    title: 'تتبع الرحلات مباشر',
    description: 'تتبع رحلتك على الخريطة في الوقت الفعلي مع تحديث الموقع.',
  ),
  _FeatureItem(
    icon: Icons.gps_fixed_rounded,
    title: 'GPS دقيق',
    description: 'نظام GPS دقيق مع كشف التلاعب بالموقع لضمان الشفافية.',
  ),
  _FeatureItem(
    icon: Icons.people_rounded,
    title: 'رحلات تشاركية',
    description: 'إمكانية مشاركة الرحلة مع راكب آخر وتقسيم الأجرة.',
  ),
  _FeatureItem(
    icon: Icons.schedule_rounded,
    title: 'رحلات مجدولة',
    description: 'حجز رحلات مسبقاً بموعد محدد يناسب جدولك.',
  ),
  _FeatureItem(
    icon: Icons.wallet_rounded,
    title: 'محفظة إلكترونية',
    description: 'استلام المدفوعات إلكترونياً وسحب الأموال بسهولة.',
  ),
  _FeatureItem(
    icon: Icons.offline_bolt_rounded,
    title: 'تعمل بدون إنترنت',
    description: 'استمر في العمل حتى عند انقطاع الاتصال بالإنترنت.',
  ),
  _FeatureItem(
    icon: Icons.subscriptions_rounded,
    title: 'نظام الباقات',
    description: 'اشتراكات شهرية لمزايا إضافية ونسبة عمولة أقل.',
  ),
];

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      color: AppTheme.meterCard,
      child: Column(
        children: [
          const Text(
            'مميزات التطبيق',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'كل ما تحتاجه في تطبيق واحد',
            style: TextStyle(fontSize: 15, color: AppTheme.meterMuted),
          ),
          const SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isWide ? 4 : 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: isWide ? 1.1 : 0.95,
            ),
            itemCount: _features.length,
            itemBuilder: (_, i) => _FeatureCard(item: _features[i]),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgDeep,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.meterCard.withAlpha(120)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: AppTheme.meterPrimary.withAlpha(25), borderRadius: BorderRadius.circular(12)),
            child: Icon(item.icon, color: AppTheme.meterPrimary, size: 24),
          ),
          const SizedBox(height: 14),
          Text(item.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          Expanded(
            child: Text(item.description, style: const TextStyle(fontSize: 12, color: AppTheme.meterMuted, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

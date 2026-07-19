import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class HeroSection extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLearnMore;

  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: isWide ? 80 : 48),
      child: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildNarrowLayout() {
    return Column(
      children: [
        _buildHeroIcon(),
        const SizedBox(height: 24),
        _buildHeroText(),
        const SizedBox(height: 32),
        _buildCTAButtons(),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroText(),
              const SizedBox(height: 32),
              _buildCTAButtons(),
            ],
          ),
        ),
        const SizedBox(width: 48),
        _buildMockupImage(),
      ],
    );
  }

  Widget _buildHeroIcon() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.meterPrimary.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.local_taxi_rounded, size: 44, color: AppTheme.meterPrimary),
    );
  }

  Widget _buildHeroText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'عدادي مَرِنْ',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
        ),
        SizedBox(height: 8),
        Text(
          'توقع أجرتك',
          style: TextStyle(fontSize: 20, color: AppTheme.meterPrimary, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 16),
        Text(
          'التطبيق الذكي لحساب الأجرة وتتبع الرحلات.\nلسائقي و ركاب التوك توك في مصر.',
          style: TextStyle(fontSize: 16, color: AppTheme.meterMuted, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCTAButtons() {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.meterPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('ابدأ الآن', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        SizedBox(
          height: 52,
          child: OutlinedButton(
            onPressed: onLearnMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.meterPrimary,
              side: const BorderSide(color: AppTheme.meterPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('اعرف أكثر', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildMockupImage() {
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: AppTheme.meterCard.withAlpha(80),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.phone_android, size: 80, color: AppTheme.meterPrimary),
          const SizedBox(height: 16),
          Text('واجهة التطبيق', style: TextStyle(color: AppTheme.meterMuted.withAlpha(180))),
        ],
      ),
    );
  }
}

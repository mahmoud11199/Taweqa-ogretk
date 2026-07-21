import 'package:flutter/material.dart';

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
      width: 80, height: 80,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF00E5B8), Color(0xFF0088CC)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.local_taxi_rounded, size: 44, color: Color(0xFF080D18)),
    );
  }

  Widget _buildHeroText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'عدادي ',
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFFEDF2FC), letterSpacing: 1),
            children: [
              TextSpan(text: 'مَرِنْ', style: TextStyle(color: Color(0xFF00E5B8))),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('توقع أجرتك', style: TextStyle(fontSize: 20, color: Color(0xFF00E5B8), fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        const Text(
          'التطبيق الذكي لحساب الأجرة وتتبع الرحلات.\nلسائقي و ركاب التوك توك في مصر.',
          style: TextStyle(fontSize: 16, color: Color(0xFF526480), height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCTAButtons() {
    return Wrap(
      spacing: 16, runSpacing: 12,
      children: [
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: onGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5B8),
              foregroundColor: const Color(0xFF080D18),
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
              foregroundColor: const Color(0xFF00E5B8),
              side: const BorderSide(color: Color(0xFF00E5B8)),
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
      width: 300, height: 400,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.phone_android, size: 80, color: Color(0xFF00E5B8)),
          SizedBox(height: 16),
          Text('واجهة التطبيق', style: TextStyle(color: Color(0xFF3A5070))),
        ],
      ),
    );
  }
}

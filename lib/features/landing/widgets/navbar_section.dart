import 'package:flutter/material.dart';

class NavbarSection extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final VoidCallback? onScrollToFeatures;
  final VoidCallback? onScrollToHowItWorks;
  final VoidCallback? onScrollToDownload;

  const NavbarSection({
    super.key,
    required this.onLogin,
    required this.onRegister,
    this.onScrollToFeatures,
    this.onScrollToHowItWorks,
    this.onScrollToDownload,
  });

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: Color(0xFF080D18),
        border: Border(bottom: BorderSide(color: Color(0xFF1C2B45), width: 1)),
      ),
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(0, 229, 184, 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_taxi_rounded, size: 20, color: Color(0xFF00E5B8)),
              ),
              const SizedBox(width: 10),
              const Text('عدادي مَرِنْ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
            ],
          ),
          if (isWide) ...[
            const Spacer(),
            _NavLink(label: 'المميزات', onTap: onScrollToFeatures),
            const SizedBox(width: 24),
            _NavLink(label: 'طريقة العمل', onTap: onScrollToHowItWorks),
            const SizedBox(width: 24),
            _NavLink(label: 'تحميل التطبيق', onTap: onScrollToDownload),
            const SizedBox(width: 32),
          ],
          const Spacer(),
          TextButton(onPressed: onLogin, child: const Text('تسجيل الدخول', style: TextStyle(color: Color(0xFF00E5B8)))),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onRegister,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E5B8),
              foregroundColor: const Color(0xFF080D18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('إنشاء حساب', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _NavLink extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _NavLink({required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label, style: const TextStyle(color: Color(0xFF526480), fontSize: 14, fontWeight: FontWeight.w500)),
    );
  }
}

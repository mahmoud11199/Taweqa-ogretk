import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 40),
      color: const Color(0xFF080D18),
      child: Column(
        children: [
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FooterColumn(
                  title: 'عدادي مَرِنْ',
                  items: [
                    _FooterLink(label: 'التوك توك الذكي لحساب الأجر', onTap: null),
                    _FooterLink(label: 'وتتبع الرحلات في مصر', onTap: null),
                  ],
                ),
                const Spacer(),
                const _FooterColumn(
                  title: 'روابط سريعة',
                  items: [
                    _FooterLink(label: 'المميزات', onTap: null),
                    _FooterLink(label: 'طريقة العمل', onTap: null),
                    _FooterLink(label: 'تحميل التطبيق', onTap: null),
                  ],
                ),
                const SizedBox(width: 48),
                _FooterColumn(
                  title: 'تواصل معنا',
                  items: [
                    _FooterLink(label: 'فيسبوك', onTap: () => launchUrl(Uri.parse('https://facebook.com'), mode: LaunchMode.externalApplication)),
                    _FooterLink(label: 'واتساب', onTap: () => launchUrl(Uri.parse('https://wa.me/'), mode: LaunchMode.externalApplication)),
                    _FooterLink(label: 'البريد الإلكتروني', onTap: () => launchUrl(Uri.parse('mailto:support@taweqa.app'), mode: LaunchMode.externalApplication)),
                  ],
                ),
              ],
            )
          else
            Column(
              children: [
                const Text('عدادي مَرِنْ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 4),
                const Text('التوك توك الذكي', style: TextStyle(fontSize: 13, color: Color(0xFF526480))),
                const SizedBox(height: 24),
                const Text('روابط سريعة', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 8),
                Wrap(spacing: 16, children: ['المميزات', 'طريقة العمل', 'تحميل التطبيق'].map((l) => Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF526480)))).toList()),
                const SizedBox(height: 24),
                const Text('تواصل معنا', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 8),
                Wrap(spacing: 12, children: ['فيسبوك', 'واتساب', 'بريد إلكتروني'].map((l) => Text(l, style: const TextStyle(fontSize: 13, color: Color(0xFF526480)))).toList()),
              ],
            ),
          const SizedBox(height: 32),
          const Divider(color: Color(0xFF1C2B45)),
          const SizedBox(height: 16),
          const Text('© 2025 عدادِي مَرِنْ. جميع الحقوق محفوظة.', style: TextStyle(fontSize: 12, color: Color(0xFF526480))),
        ],
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<_FooterLink> items;
  const _FooterColumn({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: item.onTap,
                child: Text(item.label, style: const TextStyle(fontSize: 13, color: Color(0xFF526480))),
              ),
            )),
      ],
    );
  }
}

class _FooterLink {
  final String label;
  final VoidCallback? onTap;
  const _FooterLink({required this.label, this.onTap});
}

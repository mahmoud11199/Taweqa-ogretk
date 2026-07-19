import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class _Step {
  final String number;
  final String title;
  final String description;
  const _Step({required this.number, required this.title, required this.description});
}

const List<_Step> _driverSteps = [
  _Step(number: '1', title: 'حمل التطبيق', description: 'حمل عدادِي مَرِنْ من المتجر وأنشئ حسابك كسائق.'),
  _Step(number: '2', title: 'فعّل حسابك', description: 'ارفع المستندات المطلوبة وانتظر الموافقة.'),
  _Step(number: '3', title: 'ابدأ العمل', description: 'افتح التطبيق، حدد "متاح" واستقبل الرحلات.'),
];

const List<_Step> _passengerSteps = [
  _Step(number: '1', title: 'حمل التطبيق', description: 'حمل عدادِي مَرِنْ من المتجر وسجل كراكب.'),
  _Step(number: '2', title: 'حدد وجهتك', description: 'ادخل موقع الانطلاق والوجهة على الخريطة.'),
  _Step(number: '3', title: 'استمتع بالرحلة', description: 'شاهد الأجرة مسبقاً وتابع رحلتك مباشر.'),
];

class HowItWorksSection extends StatefulWidget {
  const HowItWorksSection({super.key});

  @override
  State<HowItWorksSection> createState() => _HowItWorksSectionState();
}

class _HowItWorksSectionState extends State<HowItWorksSection> {
  bool _showDriver = true;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isWide ? 80 : 24, vertical: 64),
      child: Column(
        children: [
          const Text('طريقة العمل', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 8),
          const Text('اختر دورك لمعرفة كيف يعمل التطبيق', style: TextStyle(fontSize: 15, color: AppTheme.meterMuted)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoleTab(label: 'سائق', selected: _showDriver, onTap: () => setState(() => _showDriver = true)),
              const SizedBox(width: 12),
              _RoleTab(label: 'راكب', selected: !_showDriver, onTap: () => setState(() => _showDriver = false)),
            ],
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: (_showDriver ? _driverSteps : _passengerSteps).map((step) {
              return Container(
                width: isWide ? 220 : 160,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.meterPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(child: Text(step.number, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
                    ),
                    const SizedBox(height: 14),
                    Text(step.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(step.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppTheme.meterMuted, height: 1.5)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.meterPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? AppTheme.meterPrimary : AppTheme.meterCard),
        ),
        child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppTheme.meterMuted)),
      ),
    );
  }
}

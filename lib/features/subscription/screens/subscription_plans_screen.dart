import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('باقات الاشتراك', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state.subscribeSuccess) showToast(context, 'تم الاشتراك بنجاح!');
          if (state.error != null) showToast(context, state.error!, isError: true);
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _PlanCard(
                title: 'باقة الركاب', subtitle: 'خصم 15% على قيمة كل رحلة',
                price: AppConstants.passengerSubPrice,
                features: const ['خصم 15% على الأجرة', 'أولوية في العثور على سائق', 'دعم فني متميز'],
                icon: Icons.discount, color: const Color(0xFF0088CC),
                onSubscribe: () => context.read<SubscriptionBloc>().add(
                  Subscribe(tierType: 'passenger_discount', price: AppConstants.passengerSubPrice.toDouble()),
                ),
                isLoading: state.isLoading,
                isActive: state.activeSubscription?.isPassengerDiscount ?? false,
              ),
              const SizedBox(height: 16),
              _PlanCard(
                title: 'باقة السائقين بريميوم', subtitle: 'زيادة الأرباح و أولوية في الرحلات',
                price: AppConstants.driverSubPrice,
                features: const ['عمولة مخفضة 10% بدلاً من 15%', 'أولوية في استقبال الرحلات', 'إحصائيات متقدمة', 'دعم فني متميز'],
                icon: Icons.star, color: const Color(0xFFFFB020),
                onSubscribe: () => context.read<SubscriptionBloc>().add(
                  Subscribe(tierType: 'driver_premium', price: AppConstants.driverSubPrice.toDouble()),
                ),
                isLoading: state.isLoading,
                isActive: state.activeSubscription?.isDriverPremium ?? false,
              ),
              if (state.activeSubscription != null) ...[
                const SizedBox(height: 24),
                _CurrentSubCard(state: state),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int price;
  final List<String> features;
  final IconData icon;
  final Color color;
  final VoidCallback onSubscribe;
  final bool isLoading;
  final bool isActive;

  const _PlanCard({
    required this.title, required this.subtitle, required this.price,
    required this.features, required this.icon, required this.color,
    required this.onSubscribe, required this.isLoading, required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final c = isActive ? const Color(0xFF00E5B8) : color;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [const Color.fromRGBO(0, 229, 184, 0.1), const Color(0xFF0F1628)]
              : [const Color(0xFF0F1628), const Color(0xFF0C1220)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isActive ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45), width: isActive ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF526480))),
                ],
              )),
              RichText(
                text: TextSpan(
                  text: '$price', style: TextStyle(fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w900, color: c, height: 1),
                  children: [TextSpan(text: '  ج', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c))],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('شهرياً', style: TextStyle(fontSize: 12, color: Color(0xFF3A5070))),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: c, size: 18),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(fontSize: 13, color: Color(0xFF8EA4C8))),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 48,
            child: ElevatedButton(
              onPressed: isActive ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: c,
                foregroundColor: const Color(0xFF080D18),
                disabledBackgroundColor: const Color(0xFF00E5B8),
                disabledForegroundColor: const Color(0xFF080D18),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF080D18)))
                  : Text(isActive ? 'مشترك' : 'اشترك الآن', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentSubCard extends StatelessWidget {
  final SubscriptionState state;
  const _CurrentSubCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final sub = state.activeSubscription!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 229, 184, 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.subscriptions, color: Color(0xFF00E5B8), size: 28),
          ),
          const SizedBox(height: 12),
          const Text('الاشتراك الحالي', style: TextStyle(fontSize: 13, color: Color(0xFF526480))),
          const SizedBox(height: 4),
          Text(
            sub.isDriverPremium ? 'باقة السائقين بريميوم' : 'باقة الركاب',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8)),
          ),
          const SizedBox(height: 4),
          Text(
            'تنتهي في ${sub.expiresAt.day}/${sub.expiresAt.month}/${sub.expiresAt.year}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF526480)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              onPressed: () => context.read<SubscriptionBloc>().add(CancelSubscription()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(255, 59, 92, 0.1),
                foregroundColor: const Color(0xFFFF3B5C),
                side: const BorderSide(color: Color(0xFFFF3B5C)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('إلغاء الاشتراك', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

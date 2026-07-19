import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/toast_widget.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('باقات الاشتراك'),
        backgroundColor: AppTheme.meterCard,
      ),
      body: BlocConsumer<SubscriptionBloc, SubscriptionState>(
        listener: (context, state) {
          if (state.subscribeSuccess) {
            showToast(context, 'تم الاشتراك بنجاح!');
          }
          if (state.error != null) {
            showToast(context, state.error!, isError: true);
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _PlanCard(
                title: 'باقة الركاب',
                subtitle: 'خصم 15% على قيمة كل رحلة',
                price: AppConstants.passengerSubPrice,
                features: const ['خصم 15% على الأجرة', 'أولوية في العثور على سائق', 'دعم فني متميز'],
                icon: Icons.discount,
                onSubscribe: () => context.read<SubscriptionBloc>().add(
                  Subscribe(
                    tierType: 'passenger_discount',
                    price: AppConstants.passengerSubPrice.toDouble(),
                  ),
                ),
                isLoading: state.isLoading,
                isActive: state.activeSubscription?.isPassengerDiscount ?? false,
              ),
              const SizedBox(height: 16),
              _PlanCard(
                title: 'باقة السائقين بريميوم',
                subtitle: 'زيادة الأرباح و أولوية في الرحلات',
                price: AppConstants.driverSubPrice,
                features: const ['عمولة مخفضة 10% بدلاً من 15%', 'أولوية في استقبال الرحلات', 'إحصائيات متقدمة', 'دعم فني متميز'],
                icon: Icons.star,
                onSubscribe: () => context.read<SubscriptionBloc>().add(
                  Subscribe(
                    tierType: 'driver_premium',
                    price: AppConstants.driverSubPrice.toDouble(),
                  ),
                ),
                isLoading: state.isLoading,
                isActive: state.activeSubscription?.isDriverPremium ?? false,
              ),
              if (state.activeSubscription != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.meterCard,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      const Text('الاشتراك الحالي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        state.activeSubscription!.isDriverPremium ? 'باقة السائقين بريميوم' : 'باقة الركاب',
                        style: const TextStyle(color: AppTheme.success, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'تنتهي في ${state.activeSubscription!.expiresAt.day}/${state.activeSubscription!.expiresAt.month}/${state.activeSubscription!.expiresAt.year}',
                        style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => context.read<SubscriptionBloc>().add(CancelSubscription()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error.withValues(alpha: 0.2),
                            foregroundColor: AppTheme.error,
                            side: const BorderSide(color: AppTheme.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('إلغاء الاشتراك'),
                        ),
                      ),
                    ],
                  ),
                ),
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
  final VoidCallback onSubscribe;
  final bool isLoading;
  final bool isActive;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.features,
    required this.icon,
    required this.onSubscribe,
    required this.isLoading,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [AppTheme.success.withValues(alpha: 0.15), AppTheme.meterCard]
              : [AppTheme.meterCard, AppTheme.meterCard.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppTheme.success : AppTheme.meterMuted.withValues(alpha: 0.3),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.meterPrimary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13)),
                  ],
                ),
              ),
              Text('$price ج', style: const TextStyle(color: AppTheme.fareNeon, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('شهرياً', style: TextStyle(color: AppTheme.meterMuted, fontSize: 12)),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 18),
                const SizedBox(width: 8),
                Text(f, style: const TextStyle(color: Colors.white, fontSize: 13)),
              ],
            ),
          )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isActive ? null : onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppTheme.success : AppTheme.meterPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(isActive ? 'مشترك' : 'اشترك الآن', style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

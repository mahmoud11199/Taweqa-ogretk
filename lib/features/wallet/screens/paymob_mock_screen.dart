import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class PaymobMockScreen extends StatefulWidget {
  final String paymentKey;

  const PaymobMockScreen({super.key, required this.paymentKey});

  @override
  State<PaymobMockScreen> createState() => _PaymobMockScreenState();
}

class _PaymobMockScreenState extends State<PaymobMockScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('الدفع')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.meterCard,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 64, color: AppTheme.meterPrimary),
              const SizedBox(height: 16),
              const Text(
                'محاكاة الدفع عبر Paymob',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.bgDeep,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.paymentKey,
                  style: const TextStyle(
                    color: AppTheme.meterMuted,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تم الدفع بنجاح ✅', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.meterMuted,
                    side: const BorderSide(color: AppTheme.meterBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('إلغاء ❌', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

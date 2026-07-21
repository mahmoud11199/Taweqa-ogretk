import 'package:flutter/material.dart';

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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        title: const Text('الدفع', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)), onPressed: () => Navigator.pop(context)),
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1628),
            border: Border.all(color: const Color(0xFF1C2B45)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 64, color: Color(0xFF00E5B8)),
              const SizedBox(height: 16),
              const Text('محاكاة الدفع عبر Paymob', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF080D18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(widget.paymentKey, style: const TextStyle(color: Color(0xFF526480), fontSize: 12, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity, height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5B8),
                    foregroundColor: const Color(0xFF080D18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('تم الدفع بنجاح ✅', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity, height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF526480),
                    side: const BorderSide(color: Color(0xFF1C2B45)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

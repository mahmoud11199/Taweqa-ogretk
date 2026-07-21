import 'package:flutter/material.dart';

class DriverPaymentScreen extends StatefulWidget {
  const DriverPaymentScreen({super.key});

  @override
  State<DriverPaymentScreen> createState() => _DriverPaymentScreenState();
}

class _DriverPaymentScreenState extends State<DriverPaymentScreen> {
  int _method = 0;

  static const _breakdown = [
    {'label': 'Base Fare', 'amount': 10.00, 'note': ''},
    {'label': 'Distance Fare', 'amount': 14.94, 'note': '8.3 km × 1.80 EGP'},
    {'label': 'Time Fare', 'amount': 3.60, 'note': '24 min × 0.15 EGP'},
    {'label': 'Wait Time Fare', 'amount': 1.00, 'note': '2 min × 0.50 EGP'},
  ];

  static const _methods = [
    {'icon': '💵', 'label': 'Cash', 'sub': 'Collect directly from passenger'},
    {'icon': '💳', 'label': 'Paymob', 'sub': 'Card, wallet, or Paymob balance'},
    {'icon': '📱', 'label': 'Vodafone Cash', 'sub': 'Direct mobile wallet transfer'},
  ];

  double get _total => _breakdown.fold(0.0, (s, b) => s + (b['amount'] as double));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trip Checkout', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
          child: Column(
            children: [
              // Passenger card
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF0C1220),
                  border: Border.all(color: const Color(0xFF1C2B45)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF152038),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(child: Text('👨', style: TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ahmed Hassan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                          const SizedBox(height: 2),
                          const Text('Tahrir Sq → Zamalek Club · 8.3 km', style: TextStyle(fontSize: 12, color: Color(0xFF526480))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              ...List.generate(5, (i) => const Icon(Icons.star, size: 12, color: Color(0xFFFFB020))),
                              const SizedBox(width: 4),
                              const Text('4.8 avg rating', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Fare breakdown
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1628),
                  border: Border.all(color: const Color(0xFF1C2B45)),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FARE BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.66)),
                    const SizedBox(height: 14),
                    ..._breakdown.map((b) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b['label'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF8EA4C8))),
                                if ((b['note'] as String).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(b['note'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF526480))),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            (b['amount'] as double).toStringAsFixed(2),
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC)),
                          ),
                        ],
                      ),
                    )),
                    Container(height: 1, color: const Color(0xFF1C2B45)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _total.toStringAsFixed(2),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFFFB020),
                                shadows: [Shadow(color: Color.fromRGBO(255, 176, 32, 0.4), blurRadius: 20)],
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text('EGP', style: TextStyle(fontSize: 14, color: Color(0xFF526480))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              // Payment methods
              const Text('PAYMENT METHOD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.66)),
              const SizedBox(height: 12),
              ...List.generate(_methods.length, (i) {
                final m = _methods[i];
                final selected = _method == i;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: GestureDetector(
                    onTap: () => setState(() => _method = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                      decoration: BoxDecoration(
                        color: selected ? const Color.fromRGBO(0, 229, 184, 0.06) : const Color(0xFF0F1628),
                        border: Border.all(
                          color: selected ? const Color(0xFF00E5B8) : const Color(0xFF1C2B45),
                          width: selected ? 2 : 1.5,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Text(m['icon'] as String, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m['label'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                                const SizedBox(height: 2),
                                Text(m['sub'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                              ],
                            ),
                          ),
                          Container(
                            width: 22, height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: selected ? const Color(0xFF00E5B8) : Colors.transparent,
                              border: Border.all(
                                color: selected ? const Color(0xFF00E5B8) : const Color(0xFF243558),
                                width: 2,
                              ),
                            ),
                            child: selected
                                ? const Icon(Icons.check, size: 13, color: Color(0xFF080D18))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 22),
              // Confirm button
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5B8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Confirm Payment — ${_total.toStringAsFixed(2)} EGP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF080D18)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Cancel button
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF1C2B45)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Cancel Trip',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF8EA4C8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

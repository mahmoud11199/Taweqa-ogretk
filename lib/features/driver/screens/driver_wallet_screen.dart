import 'package:flutter/material.dart';

class DriverWalletScreen extends StatefulWidget {
  const DriverWalletScreen({super.key});

  @override
  State<DriverWalletScreen> createState() => _DriverWalletScreenState();
}

class _DriverWalletScreenState extends State<DriverWalletScreen> {
  bool _rechargeOpen = false;

  static const _txns = [
    {'type': 'earn', 'label': 'Trip completed', 'detail': 'Ahmed H. · Tahrir→Zamalek', 'amount': 34.50, 'time': '2h ago'},
    {'type': 'earn', 'label': 'Trip completed', 'detail': 'Sara M. · Tahrir→Dokki', 'amount': 18.40, 'time': '4h ago'},
    {'type': 'fee', 'label': 'Platform fee', 'detail': 'Deducted automatically', 'amount': -5.00, 'time': '4h ago'},
    {'type': 'earn', 'label': 'Trip completed', 'detail': 'Mohamed A. · Heliopolis→Maadi', 'amount': 62.00, 'time': 'Yesterday'},
    {'type': 'earn', 'label': 'Trip completed', 'detail': 'Nour K. · Zamalek→Giza', 'amount': 44.80, 'time': 'Yesterday'},
    {'type': 'sub', 'label': 'Subscription', 'detail': 'Pro plan auto-renewal', 'amount': -299.00, 'time': '3 days ago'},
  ];

  static const _weekData = [320.0, 480.0, 390.0, 560.0, 720.0, 890.0, 642.0];

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
        title: const Text('Wallet & Subscription', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
            child: Column(
              children: [
                _buildBalanceCard(),
                const SizedBox(height: 14),
                _buildSubscriptionCard(),
                const SizedBox(height: 18),
                _buildChartCard(),
                const SizedBox(height: 18),
                const Text('TRANSACTION HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55)),
                const SizedBox(height: 12),
                ...List.generate(_txns.length, (i) => _buildTransactionRow(i)),
              ],
            ),
          ),
          if (_rechargeOpen) _buildRechargeModal(),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF001A14), Color(0xFF002E22), Color(0xFF001E30)],
        ),
        border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40, top: -40,
            child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(0, 229, 184, 0.04))),
          ),
          Positioned(
            right: 20, bottom: -20,
            child: Container(width: 80, height: 80, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(0, 229, 184, 0.04))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WALLET BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.7)),
              const SizedBox(height: 8),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('1,248', style: TextStyle(fontFamily: 'monospace', fontSize: 42, fontWeight: FontWeight.w800, color: Color(0xFF00E5B8), height: 1)),
                  Text('.90', style: TextStyle(fontFamily: 'monospace', fontSize: 22, color: Color(0xFF00B896))),
                  SizedBox(width: 6),
                  Text('EGP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF526480))),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _rechargeOpen = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5B8),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('+ Recharge', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF080D18))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 229, 184, 0.1),
                        border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.25)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('Withdraw', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF00E5B8))),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1200), Color(0xFF2A1E00), Color(0xFF201200)],
        ),
        border: Border.all(color: const Color.fromRGBO(255, 176, 32, 0.2)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30, top: -30,
            child: Container(width: 120, height: 120, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color.fromRGBO(255, 176, 32, 0.04))),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MONTHLY PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.6)),
                        SizedBox(height: 6),
                        Text.rich(TextSpan(
                          text: '299 ',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFFFFB020), height: 1),
                          children: [TextSpan(text: 'EGP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))],
                        )),
                        SizedBox(height: 4),
                        Text('Pro Driver · Renews Aug 20, 2026', style: TextStyle(fontSize: 12, color: Color(0xFF8EA4C8))),
                      ],
                    ),
                  ),
                  _BadgeWallet(label: 'ACTIVE', color: 'amber'),
                ],
              ),
              const SizedBox(height: 12),
              // Progress bar
              Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: Stack(
                        children: [
                          Container(height: 5, color: const Color.fromRGBO(255, 176, 32, 0.12)),
                          const FractionallySizedBox(
                            widthFactor: 0.65,
                            child: _SubProgress(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Text('20 days used', style: TextStyle(fontSize: 10, color: Color(0xFF526480))),
                      Spacer(),
                      Text('11 days remaining', style: TextStyle(fontSize: 10, color: Color(0xFF526480))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats
              const Row(
                children: [
                  _SubStat(value: '142', label: 'Trips this month'),
                  _SubStat(value: '4,830', label: 'EGP earned'),
                  _SubStat(value: '4.87', label: 'Avg. rating'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("This Week's Earnings", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: CustomPaint(
              size: const Size(double.infinity, 90),
              painter: _AreaChartPainter(data: _weekData, color: const Color(0xFF00E5B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(int i) {
    final txn = _txns[i];
    final amount = txn['amount'] as double;
    final type = txn['type'] as String;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1C2B45))),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: type == 'earn'
                  ? const Color.fromRGBO(0, 229, 184, 0.1)
                  : type == 'sub'
                      ? const Color.fromRGBO(255, 176, 32, 0.1)
                      : const Color.fromRGBO(255, 59, 92, 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              type == 'earn' ? Icons.arrow_upward : type == 'sub' ? Icons.refresh : Icons.arrow_downward,
              size: 18,
              color: type == 'earn' ? const Color(0xFF00E5B8) : type == 'sub' ? const Color(0xFFFFB020) : const Color(0xFFFF3B5C),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(txn['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                const SizedBox(height: 2),
                Text(txn['detail'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF526480))),
                Text(txn['time'] as String, style: const TextStyle(fontSize: 10, color: Color(0xFF3A5070))),
              ],
            ),
          ),
          Text(
            '${amount >= 0 ? '+' : ''}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: amount > 0 ? const Color(0xFF00E5B8) : const Color(0xFFFF3B5C),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRechargeModal() {
    return GestureDetector(
      onTap: () => setState(() => _rechargeOpen = false),
      child: Container(
        color: const Color.fromRGBO(4, 7, 14, 0.8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 48),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F1628),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF243558),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Recharge Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                    const SizedBox(height: 18),
                    _rechargeOption(icon: '💳', label: 'Paymob', sub: 'Credit/debit card or Paymob wallet'),
                    _rechargeOption(icon: '📱', label: 'Vodafone Cash', sub: 'Instant mobile wallet top-up'),
                    _rechargeOption(icon: '🏦', label: 'Bank Transfer', sub: 'EGP wire transfer (1–2 business days)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rechargeOption({required String icon, required String label, required String sub}) {
    return GestureDetector(
      onTap: () => setState(() => _rechargeOpen = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
        decoration: BoxDecoration(
          color: const Color(0xFF0C1220),
          border: Border.all(color: const Color(0xFF1C2B45)),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: Color(0xFF243558)),
          ],
        ),
      ),
    );
  }
}

// ─── Sub Stat ─────────────────────────────────────────────────────────────────
class _SubStat extends StatelessWidget {
  final String value;
  final String label;
  const _SubStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 176, 32, 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFFFB020))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF526480))),
          ],
        ),
      ),
    );
  }
}

// ─── Sub Progress Bar ─────────────────────────────────────────────────────────
class _SubProgress extends StatelessWidget {
  const _SubProgress();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 5,
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFFFB020), Color(0xFFE89800)]),
      ),
    );
  }
}

// ─── Badge ────────────────────────────────────────────────────────────────────
class _BadgeWallet extends StatelessWidget {
  final String label;
  final String color;
  const _BadgeWallet({required this.label, required this.color});

  Color _fg() {
    switch (color) {
      case 'amber': return const Color(0xFFFFB020);
      case 'teal': return const Color(0xFF00E5B8);
      case 'red': return const Color(0xFFFF3B5C);
      default: return const Color(0xFF8EA4C8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fg = _fg();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fg.withAlpha(30),
        border: Border.all(color: fg.withAlpha(71)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.6)),
    );
  }
}

// ─── Area Chart Painter ──────────────────────────────────────────────────────
class _AreaChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _AreaChartPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    final stepX = size.width / (data.length - 1);
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - ((data[i] - minVal) / range) * (size.height - 20) - 10;
      points.add(Offset(x, y));
    }

    // Fill area
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withAlpha(64), color.withAlpha(0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    path.lineTo(points.last.dx, size.height);
    path.close();
    canvas.drawPath(path, fillPaint);

    // Draw line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Draw dots
    for (final p in points) {
      canvas.drawCircle(p, 3, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_AreaChartPainter oldDelegate) => oldDelegate.data != data;
}

import 'dart:async';
import 'package:flutter/material.dart';

class DriverDispatchScreen extends StatefulWidget {
  const DriverDispatchScreen({super.key});

  @override
  State<DriverDispatchScreen> createState() => _DriverDispatchScreenState();
}

class _DriverDispatchScreenState extends State<DriverDispatchScreen> {
  int _tab = 0;
  bool _showReq = true;
  int _count = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!_showReq || _count <= 0) {
        t.cancel();
        return;
      }
      setState(() => _count--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _simulateRequest() {
    setState(() {
      _showReq = true;
      _count = 30;
    });
    _startCountdown();
  }

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
        title: const Text('Trip Dispatch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 19, color: Color(0xFF526480)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Tab bar
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1220),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: ['Instant', 'Scheduled'].asMap().entries.map((e) {
                      final i = e.key;
                      final label = e.value;
                      final active = _tab == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? const Color(0xFF00E5B8) : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              '${i == 0 ? '⚡ ' : '📅 '}$label',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: active ? const Color(0xFF080D18) : const Color(0xFF526480),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                // Tab content
                Expanded(
                  child: _tab == 0 ? _buildInstantTab() : _buildScheduledTab(),
                ),
              ],
            ),
          ),
          // Request modal overlay
          if (_showReq)
            GestureDetector(
              onTap: () {},
              child: Container(
                color: const Color.fromRGBO(4, 7, 14, 0.82),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: _buildRequestModal(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstantTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔔', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text('Listening for requests…', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF8EA4C8))),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Stay online to receive live trip requests in real-time',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF526480), height: 1.6),
            ),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: _simulateRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 229, 184, 0.08),
                border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.3)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Simulate incoming request →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00E5B8))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledTab() {
    final trips = [
      {'time': '14:30', 'date': 'Today', 'from': 'Cairo International Airport', 'to': 'Maadi Corniche', 'fare': '145', 'dist': '28 km', 'tier': 'Private Car', 'taken': false},
      {'time': '09:15', 'date': 'Tomorrow', 'from': 'Heliopolis — Roxy Square', 'to': 'Downtown Cairo', 'fare': '62', 'dist': '12 km', 'tier': 'Private Car', 'taken': true},
      {'time': '16:45', 'date': 'Tomorrow', 'from': 'Mohandessin — Sphinx Sq', 'to': 'Giza Pyramids Area', 'fare': '88', 'dist': '15 km', 'tier': 'TukTuk', 'taken': false},
      {'time': '08:00', 'date': 'Thu Jul 22', 'from': 'Zamalek Club', 'to': 'Sheikh Zayed City', 'fare': '210', 'dist': '38 km', 'tier': 'Private Car', 'taken': false},
    ];
    final available = trips.where((t) => t['taken'] == false).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        Text(
          '$available available trips to claim',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.55),
        ),
        const SizedBox(height: 15),
        ...trips.map((trip) => _buildTripCard(trip)),
      ],
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final taken = trip['taken'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        border: Border.all(color: taken ? const Color(0xFF152038) : const Color(0xFF1C2B45)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Opacity(
        opacity: taken ? 0.55 : 1,
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(trip['time'] as String, style: const TextStyle(fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                          const SizedBox(width: 8),
                          Text(trip['date'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF526480))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(trip['from'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF8EA4C8), height: 1.5)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.chevron_right, size: 11, color: Color(0xFF526480)),
                          const SizedBox(width: 4),
                          Text(trip['to'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF526480))),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(trip['fare'] as String, style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFFFFB020))),
                    const Text('EGP est.', style: TextStyle(fontSize: 10, color: Color(0xFF526480))),
                    const SizedBox(height: 2),
                    Text(trip['dist'] as String, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF8EA4C8))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _BadgeWidget(label: trip['tier'] as String, color: trip['tier'] == 'TukTuk' ? 'amber' : 'teal'),
                const Spacer(),
                if (taken)
                  const _BadgeWidget(label: 'Already Claimed', color: 'gray')
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5B8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Claim →', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF080D18))),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestModal() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1628),
            border: Border.all(color: const Color.fromRGBO(0, 229, 184, 0.4)),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [
              BoxShadow(color: Color.fromRGBO(0, 229, 184, 0.12), blurRadius: 80),
              BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.6), blurRadius: 64, offset: Offset(0, 32)),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚡ INCOMING REQUEST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.77)),
                        SizedBox(height: 5),
                        Text('Ahmed Hassan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            _BadgeWidget(label: 'Private Car', color: 'teal'),
                            SizedBox(width: 7),
                            _BadgeWidget(label: 'Shared OK', color: 'amber'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Countdown ring
                  SizedBox(
                    width: 58,
                    height: 58,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 58,
                          height: 58,
                          child: CustomPaint(
                            painter: _CountdownPainter(
                              progress: _count / 30.0,
                              color: _count < 10 ? const Color(0xFFFF3B5C) : const Color(0xFF00E5B8),
                              backgroundColor: const Color(0xFF1C2B45),
                            ),
                          ),
                        ),
                        Text(
                          '$_count',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: _count < 10 ? const Color(0xFFFF3B5C) : const Color(0xFFEDF2FC),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Route info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF080D18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Route line
                        Column(
                          children: [
                            Container(
                              width: 9, height: 9,
                              decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF00E5B8)),
                            ),
                            Expanded(
                              child: Container(
                                width: 1,
                                margin: const EdgeInsets.symmetric(vertical: 3),
                                color: const Color(0xFF243558),
                              ),
                            ),
                            Container(
                              width: 9, height: 9,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B5C),
                                borderRadius: BorderRadius.all(Radius.circular(2)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PICKUP', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.5)),
                          SizedBox(height: 3),
                          Text('Tahrir Square, Cairo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                          SizedBox(height: 14),
                          Text('DESTINATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF526480), letterSpacing: 0.5)),
                          SizedBox(height: 3),
                          Text('Zamalek Club, Cairo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                        ],
                      ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Stats row
                    Container(
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
                      ),
                      child: Row(
                        children: [
                          const _StatItem(label: 'Pickup', value: '1.2 km', color: Color(0xFF00E5B8)),
                          Container(width: 1, height: 32, color: const Color(0xFF1C2B45)),
                          const _StatItem(label: 'Trip', value: '5.4 km', color: Color(0xFFEDF2FC)),
                          Container(width: 1, height: 32, color: const Color(0xFF1C2B45)),
                          const _StatItem(label: 'Est. Fare', value: '~34 EGP', color: Color(0xFFFFB020)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _showReq = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B5C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.close, size: 16, color: Colors.white),
                            SizedBox(width: 7),
                            Text('Decline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _showReq = false);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00E5B8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, size: 16, color: Color(0xFF080D18)),
                            SizedBox(width: 7),
                            Text('Accept', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF080D18))),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Badge Widget ─────────────────────────────────────────────────────────────
class _BadgeWidget extends StatelessWidget {
  final String label;
  final String color;
  const _BadgeWidget({required this.label, required this.color});

  Color _fg() {
    switch (color) {
      case 'amber': return const Color(0xFFFFB020);
      case 'gray': return const Color(0xFF8EA4C8);
      case 'red': return const Color(0xFFFF3B5C);
      default: return const Color(0xFF00E5B8);
    }
  }

  Color _bg() => _fg().withAlpha(30);
  Color _br() => _fg().withAlpha(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bg(),
        border: Border.all(color: _br()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _fg(), letterSpacing: 0.6)),
    );
  }
}

// ─── Stat Item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF526480), letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ─── Countdown Painter ────────────────────────────────────────────────────────
class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _CountdownPainter({required this.progress, required this.color, required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -3.14159 / 2, 2 * 3.14159 * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) => oldDelegate.progress != progress || oldDelegate.color != color;
}

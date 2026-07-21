import 'package:flutter/material.dart';
import 'phone_login_screen.dart';

class Role {
  final String id;
  final String emoji;
  final String title;
  final String ar;
  final String desc;
  final Color accent;
  final String sub;

  const Role({
    required this.id,
    required this.emoji,
    required this.title,
    required this.ar,
    required this.desc,
    required this.accent,
    required this.sub,
  });
}

const _roles = [
  Role(
    id: 'driver',
    emoji: '🚗',
    title: 'Driver',
    ar: 'سائق',
    desc: 'Accept metered trips, earn transparently, manage your daily income.',
    accent: Color(0xFF00E5B8),
    sub: 'Join 2,400+ active drivers',
  ),
  Role(
    id: 'passenger',
    emoji: '👤',
    title: 'Passenger',
    ar: 'راكب',
    desc: 'Book rides with live fare preview. Split with others for lower cost.',
    accent: Color(0xFFFFB020),
    sub: 'Fair prices, real-time tracking',
  ),
  Role(
    id: 'admin',
    emoji: '📊',
    title: 'Admin',
    ar: 'مشرف',
    desc: 'Manage fleet, subscriptions and revenue from the web dashboard.',
    accent: Color(0xFF4D9FFF),
    sub: 'Full platform analytics',
  ),
];

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080D18),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Brand bar
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(11)),
                      gradient: LinearGradient(
                        begin: Alignment(-0.64, -0.64),
                        end: Alignment(0.64, 0.64),
                        colors: [Color(0xFF00E5B8), Color(0xFF0088CC)],
                      ),
                    ),
                    child: const Icon(Icons.navigation, size: 18, color: Color(0xFF050A14)),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Adady Maren', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC), height: 1, fontFamily: 'Cairo')),
                      Text('عدادي مَرِنْ', style: TextStyle(fontSize: 11, color: Color(0xFF526480))),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              // Heading
              const Text('Who are you\ntoday?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC), height: 1.1)),
              const SizedBox(height: 8),
              const Text('Select your role to get started', style: TextStyle(fontSize: 13, color: Color(0xFF526480))),
              const SizedBox(height: 32),
              // Role cards
              Expanded(
                child: ListView.separated(
                  itemCount: _roles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _RoleCard(
                    role: _roles[index],
                    onTap: () {
                      if (_roles[index].id == 'admin') {
                        Navigator.pushNamed(context, '/admin');
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneLoginScreen()));
                      }
                    },
                  ),
                ),
              ),
              // Landing link
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/landing'),
                  child: const Text('Open landing page →', style: TextStyle(fontSize: 12, color: Color(0xFF526480))),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final Role role;
  final VoidCallback onTap;

  const _RoleCard({required this.role, required this.onTap});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.role.accent;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: _hovered ? Matrix4.translationValues(0.0, -2.0, 0.0) : Matrix4.identity(),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _hovered ? accent.withAlpha(15) : const Color(0xFF0F1628),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered ? accent.withAlpha(84) : const Color(0xFF1C2B45),
              width: 1.5,
            ),
            boxShadow: _hovered
                ? [
                    const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.3), blurRadius: 32, offset: Offset(0, 8)),
                    BoxShadow(color: accent.withAlpha(33), blurRadius: 0, offset: const Offset(0, 0)),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Emoji box
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withAlpha(23),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: accent.withAlpha(48)),
                ),
                child: Center(child: Text(widget.role.emoji, style: const TextStyle(fontSize: 26))),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(widget.role.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFFEDF2FC))),
                        const SizedBox(width: 8),
                        Text(widget.role.ar, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: accent)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(widget.role.desc, style: const TextStyle(fontSize: 11, color: Color(0xFF526480), height: 1.5)),
                    const SizedBox(height: 6),
                    Text(widget.role.sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.4)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 16, color: Color(0xFF243558)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taweqa_ogretk/core/config/routes.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_bloc.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _startAnimation();
  }

  void _startAnimation() {
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        timer.cancel();
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          final authState = context.read<AuthBloc>().state;
          if (authState is AuthAuthenticated) {
            final p = authState.profile;
            final route = p.isAdmin ? '/admin' : p.isDriver ? '/driver' : '/passenger';
            Navigator.of(context).pushReplacementNamed(route);
          } else {
            Navigator.of(context).pushReplacementNamed(Routes.landing);
          }
        });
        return;
      }
      setState(() => _progress += 2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A14),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cx = constraints.maxWidth / 2;
          final cy = constraints.maxHeight / 2;
          const dotRadius = 130.0;
          const ringSizes = [340.0, 260.0, 180.0, 110.0];

          return Stack(
            children: [
              for (var i = 0; i < ringSizes.length; i++)
                Positioned(
                  left: cx - ringSizes[i] / 2,
                  top: cy - ringSizes[i] / 2,
                  child: Container(
                    width: ringSizes[i],
                    height: ringSizes[i],
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.fromRGBO(0, 229, 184, 0.04 + i * 0.025),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              for (var i = 0; i < 6; i++)
                Positioned(
                  left: cx + math.cos(i * 60.0 * math.pi / 180) * dotRadius - 2,
                  top: cy + math.sin(i * 60.0 * math.pi / 180) * dotRadius - 2,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromRGBO(0, 229, 184, 0.3),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment(0.77, -0.64),
                            end: Alignment(-0.77, 0.64),
                            colors: [Color(0xFF00E5B8), Color(0xFF0088CC)],
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromRGBO(0, 229, 184, 0.35),
                              blurRadius: 48,
                            ),
                            BoxShadow(
                              color: Color.fromRGBO(0, 0, 0, 0.4),
                              blurRadius: 32,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation,
                          size: 44,
                          color: Color(0xFF050A14),
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Adady Maren',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEDF2FC),
                          letterSpacing: 0.84,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'عدّادي مَرِنْ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00E5B8),
                          letterSpacing: 1.92,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'SMART MULTI-MODAL RIDE HAILING',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF526480),
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 44),
                      SizedBox(
                        width: 180,
                        height: 2,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(1),
                          child: Stack(
                            children: [
                              Container(
                                width: 180,
                                height: 2,
                                color: const Color(0xFF1C2B45),
                              ),
                              FractionallySizedBox(
                                widthFactor: _progress / 100.0,
                                child: Container(
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF00E5B8),
                                        Color(0xFF0088CC),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$_progress%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF526480),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

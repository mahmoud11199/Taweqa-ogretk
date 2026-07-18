import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../driver/screens/driver_meter_screen.dart';
import '../../passenger/screens/passenger_home_screen.dart';
import '../bloc/landing_cubit.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LandingCubit>().loadRelease();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final screen = state.profile.isDriver
              ? const DriverMeterScreen()
              : const PassengerHomeScreen();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => screen),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.meterPrimary.withAlpha(30),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.local_taxi_rounded,
                    size: 56,
                    color: AppTheme.meterPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'توقع أجرتك',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'التوك توك الذكي',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.meterPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'احسب أجرتك بسهولة، تتبع رحلاتك، واستلم مدفوعاتك بدون تعقيد',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.meterMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 48),
                BlocBuilder<LandingCubit, LandingState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.meterPrimary,
                        ),
                      );
                    }

                    final release = state.release;
                    final apkUrl = release?.apkUrl;
                    final iosUrl = release?.iosUrl;
                    return Column(
                      children: [
                        if (apkUrl != null) ...[
                          _DownloadButton(
                            icon: Icons.android,
                            label: 'تحميل التطبيق (Android)',
                            version: release!.version,
                            onTap: () => launchUrl(
                              Uri.parse(apkUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                        if (iosUrl != null) ...[
                          const SizedBox(height: 12),
                          _DownloadButton(
                            icon: Icons.apple,
                            label: 'تحميل (iOS)',
                            version: release!.version,
                            onTap: () => launchUrl(
                              Uri.parse(iosUrl),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                        if (release?.webUrl != null)
                          const SizedBox(height: 12),
                        if (release == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              state.error ?? 'لم نتمكن من جلب روابط التحميل، يرجى المحاولة لاحقاً',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 40),
                const Divider(color: AppTheme.meterMuted),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تسجيل الدخول',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.meterPrimary,
                      side: const BorderSide(color: AppTheme.meterPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                BlocBuilder<LandingCubit, LandingState>(
                  builder: (context, ls) => Text(
                    'الإصدار ${ls.appVersion ?? '1.0.0'}',
                    style: const TextStyle(
                      color: AppTheme.meterMuted,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String version;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.version,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text('$label v$version'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.meterCard,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

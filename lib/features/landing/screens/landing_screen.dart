import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/register_screen.dart';
import '../../driver/screens/driver_meter_screen.dart';
import '../../passenger/screens/passenger_home_screen.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../bloc/landing_cubit.dart';
import '../widgets/navbar_section.dart';
import '../widgets/hero_section.dart';
import '../widgets/features_section.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/download_section.dart';
import '../widgets/footer_section.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _howItWorksKey = GlobalKey();
  final _downloadKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<LandingCubit>().loadRelease();
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(context, duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          final screen = state.profile.isAdmin
              ? const AdminDashboardScreen()
              : state.profile.isDriver
                  ? const DriverMeterScreen()
                  : const PassengerHomeScreen();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Column(
          children: [
            NavbarSection(
              onLogin: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              onRegister: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
              onScrollToFeatures: () => _scrollTo(_featuresKey),
              onScrollToHowItWorks: () => _scrollTo(_howItWorksKey),
              onScrollToDownload: () => _scrollTo(_downloadKey),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    HeroSection(
                      onGetStarted: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      onLearnMore: () => _scrollTo(_featuresKey),
                    ),
                    FeaturesSection(key: _featuresKey),
                    HowItWorksSection(key: _howItWorksKey),
                    BlocBuilder<LandingCubit, LandingState>(
                      builder: (_, state) {
                        if (state.isLoading) {
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 64),
                            color: AppTheme.meterCard,
                            child: const Center(child: CircularProgressIndicator(color: AppTheme.meterPrimary)),
                          );
                        }
                        return DownloadSection(key: _downloadKey, apkUrl: state.release?.apkUrl, iosUrl: state.release?.iosUrl);
                      },
                    ),
                    const FooterSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

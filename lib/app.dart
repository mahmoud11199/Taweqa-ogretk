import 'package:flutter/material.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/screens/landing_screen.dart';

class TaweqeApp extends StatelessWidget {
  const TaweqeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'توقع أجرتك',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: Routes.landing,
      routes: {
        Routes.landing: (_) => const LandingScreen(),
      },
    );
  }
}

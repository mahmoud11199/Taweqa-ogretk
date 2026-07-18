import 'package:flutter/material.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/screens/landing_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';

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
        Routes.login: (_) => const LoginScreen(),
        Routes.register: (_) => const RegisterScreen(),
        Routes.forgotPassword: (_) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            backgroundColor: AppTheme.bgDeep,
            body: Center(
              child: Text('Route not found: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}

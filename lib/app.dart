import 'package:flutter/material.dart';
import 'core/config/routes.dart';
import 'core/theme/app_theme.dart';
import 'features/landing/screens/landing_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/auth/screens/forgot_password_screen.dart';
import 'features/driver/screens/driver_meter_screen.dart';
import 'features/driver/models/trip_model.dart';
import 'features/passenger/screens/passenger_home_screen.dart';
import 'features/admin/screens/admin_dashboard_screen.dart';
import 'features/admin/screens/drivers_management_screen.dart';
import 'features/admin/screens/passengers_management_screen.dart';
import 'features/admin/screens/trips_management_screen.dart';
import 'features/admin/screens/driver_applications_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
import 'features/chat/screens/chat_list_screen.dart';
import 'features/trip/screens/trip_details_screen.dart';
import 'features/rating/screens/rating_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';

class TaweqeApp extends StatelessWidget {
  const TaweqeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'توقع أجرتك',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: Routes.landing,
      onGenerateRoute: (settings) {
        Widget screen;
        switch (settings.name) {
          case Routes.landing:
            screen = const LandingScreen();
          case Routes.login:
            screen = const LoginScreen();
          case Routes.register:
            screen = const RegisterScreen();
          case Routes.forgotPassword:
            screen = const ForgotPasswordScreen();
          case Routes.driver:
            screen = const DriverMeterScreen();
          case Routes.passenger:
            screen = const PassengerHomeScreen();
          case Routes.admin:
            screen = const AdminDashboardScreen();
          case Routes.wallet:
            screen = const WalletScreen();
          case Routes.chat:
            screen = const ChatListScreen();
          case Routes.adminDrivers:
            screen = const DriversManagementScreen();
          case Routes.adminPassengers:
            screen = const PassengersManagementScreen();
          case Routes.adminTrips:
            screen = const TripsManagementScreen();
          case Routes.adminWallets:
            screen = const WalletScreen();
          case Routes.driverApplication:
            screen = const DriverApplicationsScreen();
          case Routes.settings:
            screen = const SettingsScreen();
          case Routes.editProfile:
            screen = const EditProfileScreen();
          case Routes.tripDetails:
            final trip = settings.arguments as Trip;
            screen = TripDetailsScreen(trip: trip);
          case Routes.rating:
            final requestId = settings.arguments as String? ?? '';
            screen = RatingScreen(requestId: requestId, driverName: '');
          default:
            screen = Scaffold(
              backgroundColor: AppTheme.bgDeep,
              body: Center(
                child: Text('Route not found: ${settings.name}'),
              ),
            );
        }
        return MaterialPageRoute(builder: (_) => screen, settings: settings);
      },
    );
  }
}

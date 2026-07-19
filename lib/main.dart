import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/blocs/connectivity_cubit.dart';
import 'core/config/supabase_config.dart';
import 'core/services/background_location_service.dart';
import 'core/services/in_app_notification_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/bloc/admin_bloc.dart';
import 'features/admin/repositories/admin_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/chat/bloc/chat_bloc.dart';
import 'features/chat/repositories/chat_repository.dart';
import 'features/driver/bloc/driver_bloc.dart';
import 'features/subscription/bloc/subscription_bloc.dart';
import 'features/subscription/repositories/subscription_repository.dart';
import 'features/driver/repositories/driver_repository.dart';
import 'features/landing/bloc/landing_cubit.dart';
import 'features/landing/repositories/landing_repository.dart';
import 'features/passenger/bloc/passenger_bloc.dart';
import 'features/passenger/repositories/passenger_repository.dart';
import 'features/wallet/bloc/wallet_bloc.dart';
import 'features/wallet/repositories/wallet_repository.dart';
import 'app.dart';

Widget _buildApp() {
  final authRepository = AuthRepository();
  final landingRepository = LandingRepository();
  final driverRepository = DriverRepository();
  final passengerRepository = PassengerRepository();
  final adminRepository = AdminRepository();
  final walletRepository = WalletRepository();
  final chatRepository = ChatRepository();
  final subscriptionRepository = SubscriptionRepository();

  return MultiBlocProvider(
    providers: [
      BlocProvider<ConnectivityCubit>(
        create: (_) => ConnectivityCubit(),
      ),
      BlocProvider<AuthBloc>(
        create: (_) => AuthBloc(repository: authRepository)..add(AppStarted()),
      ),
      BlocProvider<LandingCubit>(
        create: (_) => LandingCubit(repository: landingRepository),
      ),
      BlocProvider<DriverBloc>(
        create: (_) => DriverBloc(repository: driverRepository),
      ),
      BlocProvider<PassengerBloc>(
        create: (_) => PassengerBloc(repository: passengerRepository),
      ),
      BlocProvider<AdminBloc>(
        create: (_) => AdminBloc(repository: adminRepository),
      ),
      BlocProvider<WalletBloc>(
        create: (_) => WalletBloc(repository: walletRepository),
      ),
      BlocProvider<ChatBloc>(
        create: (_) => ChatBloc(repository: chatRepository),
      ),
      BlocProvider<SubscriptionBloc>(
        create: (_) => SubscriptionBloc(repository: subscriptionRepository),
      ),
    ],
    child: const TaweqeApp(),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await SupabaseConfig.init();
    await NotificationService.initialize();
    await BackgroundLocationService.initialize();
    await InAppNotificationService.initialize();
    await SyncService.startMonitoring();
  } catch (_) {
    runApp(const ErrorApp());
    return;
  }
  runApp(_buildApp());
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              const Text(
                'توقع أجرتك',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('حدث خطأ أثناء تهيئة التطبيق'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Firebase.initializeApp();
                    await SupabaseConfig.init();
                    await NotificationService.initialize();
                    await BackgroundLocationService.initialize();
                    await InAppNotificationService.initialize();
                    await SyncService.startMonitoring();
                    runApp(_buildApp());
                  } catch (_) {}
                },
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

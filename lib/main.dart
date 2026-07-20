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

Future<bool> _tryInit(bool hasFirebase) async {
  if (!hasFirebase) {
    try {
      await Firebase.initializeApp();
      hasFirebase = true;
    } catch (_) {}
  }
  await SupabaseConfig.init();
  await NotificationService.initialize(firebaseAvailable: hasFirebase);
  await BackgroundLocationService.initialize();
  await InAppNotificationService.initialize();
  await SyncService.startMonitoring();
  return true;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool firebaseOk = false;
  try {
    await Firebase.initializeApp();
    firebaseOk = true;
  } catch (_) {}

  try {
    await _tryInit(firebaseOk);
  } catch (_) {
    runApp(ErrorApp(hasFirebase: firebaseOk));
    return;
  }
  runApp(_buildApp());
}

class ErrorApp extends StatefulWidget {
  final bool hasFirebase;
  const ErrorApp({super.key, required this.hasFirebase});

  @override
  State<ErrorApp> createState() => _ErrorAppState();
}

class _ErrorAppState extends State<ErrorApp> {
  bool _retrying = false;

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
              Text(_retrying ? 'جاري إعادة المحاولة...' : 'حدث خطأ أثناء تهيئة التطبيق'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _retrying
                    ? null
                    : () async {
                        setState(() => _retrying = true);
                        try {
                          final fb = widget.hasFirebase;
                          await _tryInit(fb);
                          if (context.mounted) runApp(_buildApp());
                        } catch (_) {
                          if (context.mounted) {
                            setState(() => _retrying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('لم تنجح المحاولة، تحقق من اتصال الإنترنت')),
                            );
                          }
                        }
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/landing/bloc/landing_cubit.dart';
import 'features/landing/repositories/landing_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await SupabaseConfig.init();
  } catch (_) {}

  final authRepository = AuthRepository();
  final landingRepository = LandingRepository();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(repository: authRepository)..add(AppStarted()),
        ),
        BlocProvider<LandingCubit>(
          create: (_) => LandingCubit(repository: landingRepository),
        ),
      ],
      child: const TaweqeApp(),
    ),
  );
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
                onPressed: () {
                  WidgetsFlutterBinding.ensureInitialized();
                  SupabaseConfig.init().then((_) {
                    final authRepo = AuthRepository();
                    final landingRepo = LandingRepository();
                    runApp(
                      MultiBlocProvider(
                        providers: [
                          BlocProvider<AuthBloc>(
                            create: (_) => AuthBloc(repository: authRepo)..add(AppStarted()),
                          ),
                          BlocProvider<LandingCubit>(
                            create: (_) => LandingCubit(repository: landingRepo),
                          ),
                        ],
                        child: const TaweqeApp(),
                      ),
                    );
                  }).catchError((_) {});
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

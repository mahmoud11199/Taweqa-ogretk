import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/repositories/auth_repository.dart';
import 'features/landing/bloc/landing_cubit.dart';
import 'features/landing/repositories/landing_repository.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();

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

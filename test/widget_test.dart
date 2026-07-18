import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taweqa_ogretk/app.dart';
import 'package:taweqa_ogretk/features/admin/bloc/admin_bloc.dart';
import 'package:taweqa_ogretk/features/admin/repositories/admin_repository.dart';
import 'package:taweqa_ogretk/features/auth/bloc/auth_bloc.dart';
import 'package:taweqa_ogretk/features/auth/repositories/auth_repository.dart';
import 'package:taweqa_ogretk/features/chat/bloc/chat_bloc.dart';
import 'package:taweqa_ogretk/features/chat/repositories/chat_repository.dart';
import 'package:taweqa_ogretk/features/landing/bloc/landing_cubit.dart';
import 'package:taweqa_ogretk/features/landing/repositories/landing_repository.dart';
import 'package:taweqa_ogretk/features/wallet/bloc/wallet_bloc.dart';
import 'package:taweqa_ogretk/features/wallet/repositories/wallet_repository.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(repository: AuthRepository()),
          ),
          BlocProvider<LandingCubit>(
            create: (_) => LandingCubit(repository: LandingRepository()),
          ),
          BlocProvider<AdminBloc>(
            create: (_) => AdminBloc(repository: AdminRepository()),
          ),
          BlocProvider<WalletBloc>(
            create: (_) => WalletBloc(repository: WalletRepository()),
          ),
          BlocProvider<ChatBloc>(
            create: (_) => ChatBloc(repository: ChatRepository()),
          ),
        ],
        child: const TaweqeApp(),
      ),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

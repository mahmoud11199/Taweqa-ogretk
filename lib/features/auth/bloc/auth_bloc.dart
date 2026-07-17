import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/config/supabase_config.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription? _authSubscription;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<UpdatePhoneNumber>(_onUpdatePhoneNumber);
    on<ChangePassword>(_onChangePassword);
    on<UploadAvatar>(_onUploadAvatar);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthEventError>(_onAuthEventError);

    _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
      (data) {
        if (data.event == AuthChangeEvent.signedOut) {
          add(LogoutRequested());
        } else if (data.event == AuthChangeEvent.signedIn &&
            state is! AuthAuthenticated) {
          add(AppStarted());
        } else if (data.event == AuthChangeEvent.tokenRefreshed &&
            state is! AuthAuthenticated) {
          add(AppStarted());
        }
      },
    );
  }

  String _translateError(Object e) {
    if (e is AuthException) {
      final msg = e.message;
      if (msg.contains('Invalid login credentials') || msg.contains('invalid_credentials') || msg.contains('invalid grant')) {
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
      }
      if (msg.contains('Email not confirmed')) {
        return 'البريد الإلكتروني غير مؤكد، يرجى التحقق من بريدك';
      }
      if (msg.contains('User already registered')) {
        return 'هذا البريد مسجل بالفعل';
      }
      if (msg.contains('Weak password')) {
        return 'كلمة السر ضعيفة جداً (6 أحرف على الأقل)';
      }
      return msg;
    }
    if (e is PostgrestException) {
      return 'عذراً، حدث خطأ في الخادم، يرجى المحاولة لاحقاً';
    }
    return 'حدث خطأ غير متوقع، يرجى المحاولة لاحقاً';
  }

  bool _isProcessingStart = false;

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    if (_isProcessingStart) return;
    _isProcessingStart = true;
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        try {
          final profile = await _repository.getCurrentProfile();
          emit(AuthAuthenticated(profile: profile));
        } catch (_) {
          emit(AuthUnauthenticated());
        }
      } else {
        emit(AuthUnauthenticated());
      }
    } finally {
      _isProcessingStart = false;
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تسجيل الدخول...'));
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.user != null) {
        final profile = await _repository.getCurrentProfile();
        emit(AuthAuthenticated(profile: profile));
      } else {
        emit(AuthFailure('البريد الإلكتروني أو كلمة المرور غير صحيحة'));
      }
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onRegisterRequested(RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري إنشاء الحساب...'));
    try {
      final response = await SupabaseConfig.client.auth.signUp(
        email: event.email,
        password: event.password,
        data: {
          'full_name': event.name,
          'role': event.role,
          'phone': event.phone,
          if (event.refCode != null) 'ref': event.refCode,
        },
      );

      if (response.user == null) {
        emit(AuthFailure('فشل إنشاء الحساب'));
        return;
      }

      final userId = response.user!.id;

      await _repository.ensureProfileExists(
        response.user!, event.name, event.role, event.phone,
      );

      if (event.role == 'driver' && event.driverType != null) {
        await _repository.ensureDriverRow(userId, event.driverType!.apiValue);
        await _repository.submitDriverApplication(
          userId: userId,
          name: event.name,
          phone: event.phone,
          driverType: event.driverType!.apiValue,
          fields: event.driverFields,
          files: event.driverFiles,
        );
      }

      if (event.refCode != null && event.refCode!.isNotEmpty) {
        try {
          await SupabaseConfig.client.rpc('apply_referral', params: {
            'p_user_id': userId,
            'p_ref_code': event.refCode,
          });
        } catch (_) {}
      }

      final profile = await _repository.getCurrentProfile();
      emit(AuthAuthenticated(profile: profile));
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onForgotPasswordRequested(
      ForgotPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري إرسال رابط إعادة التعيين...'));
    try {
      await _repository.sendPasswordResetEmail(event.email);
      emit(PasswordResetSent(message: 'تم إرسال رابط إعادة التعيين إلى بريدك'));
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onResetPasswordRequested(
      ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تغيير كلمة السر...'));
    try {
      await SupabaseConfig.client.auth.updateUser(
        UserAttributes(password: event.newPassword),
      );
      emit(AuthSuccess(message: 'تم تغيير كلمة السر بنجاح'));
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onUpdatePhoneNumber(
      UpdatePhoneNumber event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تحديث رقم الهاتف...'));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        await _repository.updatePhoneNumber(user.id, event.newPhone);
        final profile = await _repository.getCurrentProfile();
        emit(AuthAuthenticated(profile: profile));
      }
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onChangePassword(
      ChangePassword event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تغيير كلمة السر...'));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null && user.email != null) {
        await _repository.changePassword(
          user.email!, event.oldPassword, event.newPassword,
        );
        emit(AuthSuccess(message: 'تم تغيير كلمة السر بنجاح'));
      }
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onUploadAvatar(
      UploadAvatar event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري رفع الصورة...'));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user != null) {
        await _repository.uploadAvatar(user.id, event.file, event.role);
        final profile = await _repository.getCurrentProfile();
        emit(AuthAuthenticated(profile: profile));
      }
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تسجيل الخروج...'));
    try {
      await SupabaseConfig.client.auth.signOut();
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthEventError(AuthEventError event, Emitter<AuthState> emit) {
    emit(AuthFailure(event.message));
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}

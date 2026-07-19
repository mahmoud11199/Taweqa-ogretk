import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../../core/config/supabase_config.dart';
import '../../../core/services/in_app_notification_service.dart';
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
    on<SendPhoneOtp>(_onSendPhoneOtp);
    on<VerifyPhoneOtp>(_onVerifyPhoneOtp);
    on<RegisterWithPhone>(_onRegisterWithPhone);

    try {
      _authSubscription = SupabaseConfig.client.auth.onAuthStateChange.listen(
        (data) {
          if (data.event == AuthChangeEvent.signedOut && state is! AuthUnauthenticated) {
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
    } catch (_) {
      // Supabase not initialized — auth subscription skipped
    }
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

  Future<UserProfile?> _tryFetchProfile() async {
    try {
      return await _repository
          .getCurrentProfile()
          .timeout(const Duration(seconds: 8));
    } catch (_) {
      return null;
    }
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      emit(AuthUnauthenticated());
      return;
    }
    final cached = UserProfile.fromSupabaseUser(user);
    emit(AuthAuthenticated(profile: cached));
    await InAppNotificationService.startListening(user.id);
    final full = await _tryFetchProfile();
    if (full != null && !isClosed) {
      emit(AuthAuthenticated(profile: full));
    }
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري تسجيل الدخول...'));
    try {
      final response = await SupabaseConfig.client.auth.signInWithPassword(
        email: event.email,
        password: event.password,
      );
      if (response.user == null) {
        emit(AuthFailure('البريد الإلكتروني أو كلمة المرور غير صحيحة'));
        return;
      }
      final cached = UserProfile.fromSupabaseUser(response.user!);
      emit(AuthAuthenticated(profile: cached));
      await InAppNotificationService.startListening(response.user!.id);
      final full = await _tryFetchProfile();
      if (full != null && !isClosed) {
        emit(AuthAuthenticated(profile: full));
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

      final user = response.user!;
      final cached = UserProfile.fromSupabaseUser(user);
      emit(AuthAuthenticated(profile: cached));
      await InAppNotificationService.startListening(user.id);

      // Background: ensure profile, wallet, driver setup, referral
      try {
        await _repository.ensureProfileExists(user, event.name, event.role, event.phone);

        if (event.role == 'driver' && event.driverType != null) {
          await _repository.ensureDriverRow(user.id, event.driverType!.apiValue);
          await _repository.submitDriverApplication(
            userId: user.id,
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
              'p_user_id': user.id,
              'p_ref_code': event.refCode,
            });
      } catch (e) {
        debugPrint('Background registration error: $e');
      }
        }

        final full = await _tryFetchProfile();
        if (full != null && !isClosed) {
          emit(AuthAuthenticated(profile: full));
        }
      } catch (_) {}
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
      } else {
        emit(AuthFailure('يجب تسجيل الدخول أولاً'));
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
      } else {
        emit(AuthFailure('يجب تسجيل الدخول أولاً'));
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
      await InAppNotificationService.stopListening();
      await SupabaseConfig.client.auth.signOut();
      emit(AuthUnauthenticated());
    } catch (_) {
      await InAppNotificationService.stopListening();
      emit(AuthUnauthenticated());
    }
  }

  void _onAuthEventError(AuthEventError event, Emitter<AuthState> emit) {
    emit(AuthFailure(event.message));
  }

  Future<void> _onSendPhoneOtp(SendPhoneOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري إرسال رمز التحقق...'));
    try {
      await _repository.sendPhoneOtp(event.phone);
      emit(PhoneOtpSent(phone: event.phone));
    } catch (e) {
      emit(AuthFailure('فشل إرسال رمز التحقق: ${_translateError(e)}'));
    }
  }

  Future<void> _onVerifyPhoneOtp(VerifyPhoneOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري التحقق...'));
    try {
      await _repository.verifyPhoneOtp(event.phone, event.otp);
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        emit(AuthFailure('فشل التحقق، يرجى المحاولة مرة أخرى'));
        return;
      }
      emit(PhoneOtpVerified(phone: event.phone));
      final profile = await _tryFetchProfile();
      if (profile != null && !isClosed) {
        emit(AuthAuthenticated(profile: profile));
        await InAppNotificationService.startListening(user.id);
      } else {
        // New user: needs registration
      }
    } catch (e) {
      emit(AuthFailure('رمز التحقق غير صحيح'));
    }
  }

  Future<void> _onRegisterWithPhone(RegisterWithPhone event, Emitter<AuthState> emit) async {
    emit(AuthLoading(message: 'جاري إنشاء الحساب...'));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) {
        emit(AuthFailure('يرجى التحقق من رقم الهاتف أولاً'));
        return;
      }
      final cached = UserProfile(
        id: user.id,
        fullName: event.name,
        role: event.role,
        phone: event.phone,
      );
      emit(AuthAuthenticated(profile: cached));
      await InAppNotificationService.startListening(user.id);
      try {
        await _repository.ensureProfileExists(user, event.name, event.role, event.phone);
        if (event.role == 'driver' && event.driverType != null) {
          await _repository.ensureDriverRow(user.id, event.driverType!.apiValue);
          await _repository.submitDriverApplication(
            userId: user.id,
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
              'p_user_id': user.id,
              'p_ref_code': event.refCode,
            });
          } catch (e) {
            debugPrint('Background registration error: $e');
          }
        }
        final full = await _tryFetchProfile();
        if (full != null && !isClosed) {
          emit(AuthAuthenticated(profile: full));
        }
      } catch (_) {}
    } catch (e) {
      emit(AuthFailure(_translateError(e)));
    }
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    _repository.dispose();
    return super.close();
  }
}

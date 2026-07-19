import '../models/user_model.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String message;
  AuthLoading({this.message = 'جاري التحميل...'});
}

class AuthUnauthenticated extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserProfile profile;

  AuthAuthenticated({required this.profile});
}


class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
}

class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});
}

class PasswordResetSent extends AuthState {
  final String message;
  PasswordResetSent({required this.message});
}

class PhoneOtpSent extends AuthState {
  final String phone;
  PhoneOtpSent({required this.phone});
}

class PhoneOtpVerified extends AuthState {
  final String phone;
  PhoneOtpVerified({required this.phone});
}

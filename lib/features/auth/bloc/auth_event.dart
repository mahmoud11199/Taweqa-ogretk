import 'dart:io';
import '../models/user_model.dart';

abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String role;
  final String? refCode;
  final DriverType? driverType;
  final Map<String, dynamic> driverFields;
  final Map<String, File?> driverFiles;

  RegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.role,
    this.refCode,
    this.driverType,
    this.driverFields = const {},
    this.driverFiles = const {},
  });
}

class ForgotPasswordRequested extends AuthEvent {
  final String email;

  ForgotPasswordRequested({required this.email});
}

class ResetPasswordRequested extends AuthEvent {
  final String newPassword;

  ResetPasswordRequested({required this.newPassword});
}

class UpdatePhoneNumber extends AuthEvent {
  final String newPhone;

  UpdatePhoneNumber({required this.newPhone});
}

class ChangePassword extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePassword({required this.oldPassword, required this.newPassword});
}

class UploadAvatar extends AuthEvent {
  final File file;
  final String role;

  UploadAvatar({required this.file, required this.role});
}

class LogoutRequested extends AuthEvent {}

class AuthEventError extends AuthEvent {
  final String message;
  AuthEventError(this.message);
}

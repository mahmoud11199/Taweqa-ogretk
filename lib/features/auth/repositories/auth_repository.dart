import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/config/supabase_config.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<UserProfile> getCurrentProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response != null) {
      return UserProfile.fromMap(response);
    }
    throw Exception('Profile not found');
  }

  Future<void> ensureProfileExists(User user, String name, String role, String phone) async {
    final existing = await _client
        .from('profiles')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'role': role,
        'phone': phone,
      });
      // Create wallet
      final wallet = await _client
          .from('wallets')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();
      if (wallet == null) {
        await _client.from('wallets').insert({'user_id': user.id, 'balance': 0});
      }
      // Create referral code
      final ref = await _client
          .from('referral_codes')
          .select('code')
          .eq('user_id', user.id)
          .maybeSingle();
      if (ref == null) {
        final code = AppConstants.generateReferralCode();
        await _client.from('referral_codes').insert({'user_id': user.id, 'code': code});
      }
    }
  }

  Future<void> ensureDriverRow(String userId, String driverType) async {
    final existing = await _client
        .from('drivers')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('drivers').insert({
        'id': userId,
        'is_available': false,
        'driver_type': driverType,
      });
    }
  }

  Future<void> submitDriverApplication({
    required String userId,
    required String name,
    required String phone,
    required String driverType,
    required Map<String, dynamic> fields,
    required Map<String, File?> files,
  }) async {
    final payload = <String, dynamic>{
      'full_name': name,
      'phone': phone,
      'driver_type': driverType,
    };

    final fieldValues = <String, String>{};
    final fileUrls = <String, String>{};

    for (final entry in fields.entries) {
      if (entry.value is String && (entry.value as String).isNotEmpty) {
        fieldValues[entry.key] = entry.value as String;
      }
    }

    for (final entry in files.entries) {
      final file = entry.value;
      if (file != null && await file.exists()) {
        try {
          final filePath = 'driver-docs/$userId/${entry.key}_${DateTime.now().millisecondsSinceEpoch}';
          final bytes = await file.readAsBytes();
          await _client.storage
              .from('driver-documents')
              .uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));

          final url = _client.storage.from('driver-documents').getPublicUrl(filePath);
          fileUrls[entry.key] = url;
          fieldValues[entry.key] = file.path.split('/').last;
        } catch (e) {
          // Upload failed, continue
        }
      } else if (entry.value is String && (entry.value as String).isNotEmpty) {
        fieldValues[entry.key] = entry.value as String;
      }
    }

    payload['fields'] = fieldValues;
    payload['fileUrls'] = fileUrls;

    await _client.from('driver_applications').upsert({
      'user_id': userId,
      'status': 'pending',
      'payload': payload,
    });
  }

  Future<void> uploadAvatar(String userId, File file, String role) async {
    final filePath = 'avatars/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final bytes = await file.readAsBytes();

    await _client.storage
        .from('avatars')
        .uploadBinary(filePath, bytes, fileOptions: const FileOptions(upsert: true));

    final url = _client.storage.from('avatars').getPublicUrl(filePath);

    await _client.from('profiles').update({'avatar_url': url}).eq('id', userId);
  }

  Future<void> updatePhoneNumber(String userId, String newPhone) async {
    await _client.from('profiles').update({'phone': newPhone}).eq('id', userId);
  }

  Future<void> changePassword(String email, String oldPassword, String newPassword) async {
    final signInResponse = await _client.auth.signInWithPassword(
      email: email,
      password: oldPassword,
    );
    if (signInResponse.user == null) {
      throw Exception('كلمة السر الحالية غير صحيحة');
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${AppConstants.supabaseUrl}/functions/v1/auth-callback',
    );
  }

  Future<void> deleteAccount(String userId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.supabaseUrl}/functions/v1/delete-user'),
      headers: {
        'Authorization': 'Bearer ${_client.auth.currentSession?.accessToken ?? ''}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'user_id': userId}),
    );
    if (response.statusCode != 200) {
      throw Exception('فشل حذف الحساب');
    }
  }

  void dispose() {
    // Auth channels cleaned up by Supabase lifecycle
  }
}

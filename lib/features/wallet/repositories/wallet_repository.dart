import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/wallet_model.dart';

class WalletRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Wallet> fetchWallet(String userId) async {
    final response = await _client
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    if (response != null) return Wallet.fromMap(response);
    // Create wallet if not exists
    await _client.from('wallets').insert({'user_id': userId, 'balance': 0});
    return Wallet(userId: userId, balance: 0);
  }

  Future<List<Transaction>> fetchTransactions(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(50);
    final list = response as List<dynamic>;
    return list.map((e) => Transaction.fromMap(e as Map<String, dynamic>)).toList();
  }

  Future<String> initPaymobPayment({
    required String userId,
    required double amount,
    required String email,
    required String phone,
    String method = 'card',
  }) async {
    // Call Supabase Edge Function to get Paymob payment key
    final functionResponse = await _client.functions.invoke('init-paymob-payment', body: {
      'user_id': userId,
      'amount': amount,
      'email': email,
      'phone': phone,
      'method': method,
    });
    final data = functionResponse.data as Map<String, dynamic>;
    return data['payment_key'] as String;
  }

  Future<bool> verifyPaymobPayment(String transactionRef) async {
    try {
      final functionResponse = await _client.functions.invoke('verify-paymob-payment', body: {
        'transaction_ref': transactionRef,
      });
      final data = functionResponse.data as Map<String, dynamic>?;
      return data?['success'] == true;
    } catch (_) {}
    return false;
  }

  Future<void> recordDeposit({
    required String userId,
    required double amount,
    required String paymobRef,
  }) async {
    await _client.rpc('record_wallet_deposit', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_paymob_ref': paymobRef,
    });
  }

  Future<void> deductFare(String userId, double amount, String tripId) async {
    await _client.rpc('deduct_wallet_fare', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_trip_id': tripId,
    });
  }
}

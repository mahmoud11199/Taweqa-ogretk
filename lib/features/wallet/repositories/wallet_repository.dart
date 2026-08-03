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

  /// Creates a pending deposit record that the SMS webhook will confirm.
  /// Returns the id of the created wallet_transactions row.
  Future<String> createPendingDeposit({
    required String userId,
    required double amount,
    required String senderPhone,
  }) async {
    final response = await _client
        .from('wallet_transactions')
        .insert({
          'user_id': userId,
          'type': 'deposit',
          'amount': amount,
          'status': 'pending',
          'sender_phone': senderPhone,
        })
        .select('id')
        .single();
    return response['id'] as String;
  }

  Future<void> deductFare(String userId, double amount, String tripId) async {
    await _client.rpc('deduct_wallet_fare', params: {
      'p_user_id': userId,
      'p_amount': amount,
      'p_trip_id': tripId,
    });
  }
}
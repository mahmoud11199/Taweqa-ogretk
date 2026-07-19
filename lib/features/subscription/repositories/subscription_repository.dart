import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../../../core/models/subscription.dart';

class SubscriptionRepository {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Subscription?> fetchActiveSubscription(String userId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .maybeSingle();
    if (response == null) return null;
    final sub = Subscription.fromMap(response);
    if (sub.isExpired) {
      await _client.from('subscriptions').update({'is_active': false}).eq('id', sub.id);
      return null;
    }
    return sub;
  }

  Future<Subscription> createSubscription({
    required String userId,
    required String tierType,
    required double price,
  }) async {
    final expiresAt = DateTime.now().add(const Duration(days: 30));
    final response = await _client.from('subscriptions').insert({
      'user_id': userId,
      'tier_type': tierType,
      'price': price,
      'expires_at': expiresAt.toIso8601String(),
      'is_active': true,
    }).select().single();
    return Subscription.fromMap(response);
  }

  Future<void> cancelSubscription(String subscriptionId) async {
    await _client
        .from('subscriptions')
        .update({'is_active': false})
        .eq('id', subscriptionId);
  }

  Future<List<Subscription>> fetchHistory(String userId) async {
    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
    final list = response as List<dynamic>;
    return list.map((e) => Subscription.fromMap(e as Map<String, dynamic>)).toList();
  }
}

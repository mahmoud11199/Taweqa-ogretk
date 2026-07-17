import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/supabase_config.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final SupabaseClient _client = SupabaseConfig.client;
  StreamSubscription? _messageSubscription;

  Future<List<Conversation>> fetchConversations(String userId) async {
    final response = await _client
        .from('conversations')
        .select()
        .or('user1_id.eq.$userId,user2_id.eq.$userId')
        .order('last_message_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((e) => Conversation.fromMap(e)).toList();
  }

  Future<String> getOrCreateConversation(String userId1, String userId2) async {
    final existing = await _client
        .from('conversations')
        .select('id')
        .or('and(user1_id.eq.$userId1,user2_id.eq.$userId2),and(user1_id.eq.$userId2,user2_id.eq.$userId1)')
        .maybeSingle();
    if (existing != null) return existing['id'] as String;
    final response = await _client.from('conversations').insert({
      'user1_id': userId1,
      'user2_id': userId2,
    }).select().single();
    return response['id'] as String;
  }

  Future<List<ChatMessage>> fetchMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    final list = response as List<dynamic>;
    return list.map((e) => ChatMessage.fromMap(e)).toList();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    String? imageUrl,
  }) async {
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'image_url': imageUrl,
    });
  }

  Stream<ChatMessage> subscribeToMessages(String conversationId) {
    final channel = _client.channel('messages:$conversationId');
    final controller = StreamController<ChatMessage>();

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        final newData = payload.newRecord;
        controller.add(ChatMessage.fromMap(newData));
      },
    );

    channel.subscribe();
    return controller.stream;
  }

  Future<void> markAsRead(String conversationId, String userId) async {
    await _client.rpc('mark_messages_read', params: {
      'p_conversation_id': conversationId,
      'p_user_id': userId,
    });
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}

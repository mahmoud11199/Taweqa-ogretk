class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      senderId: map['sender_id'] as String,
      text: map['text'] as String? ?? '',
      imageUrl: map['image_url'] as String?,
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class Conversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? otherUserName;
  final String? otherUserAvatar;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    this.otherUserName,
    this.otherUserAvatar,
    this.unreadCount = 0,
  });

  factory Conversation.fromMap(Map<String, dynamic> map) {
    return Conversation(
      id: map['id'] as String,
      user1Id: map['user1_id'] as String,
      user2Id: map['user2_id'] as String,
      lastMessage: map['last_message'] as String?,
      lastMessageAt: map['last_message_at'] != null
          ? DateTime.parse(map['last_message_at'] as String)
          : null,
      otherUserName: map['other_user_name'] as String?,
      otherUserAvatar: map['other_user_avatar'] as String?,
      unreadCount: (map['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

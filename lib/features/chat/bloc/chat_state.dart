import '../models/chat_message.dart';

class ChatState {
  final bool isLoading;
  final String? error;
  final List<Conversation> conversations;
  final List<ChatMessage> messages;
  final String? activeConversationId;

  const ChatState({
    this.isLoading = false,
    this.error,
    this.conversations = const [],
    this.messages = const [],
    this.activeConversationId,
  });

  ChatState copyWith({
    bool? isLoading,
    String? error,
    List<Conversation>? conversations,
    List<ChatMessage>? messages,
    String? activeConversationId,
    bool clearError = false,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      conversations: conversations ?? this.conversations,
      messages: messages ?? this.messages,
      activeConversationId: activeConversationId ?? this.activeConversationId,
    );
  }
}

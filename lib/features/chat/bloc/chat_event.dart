abstract class ChatEvent {}

class LoadConversations extends ChatEvent {}

class OpenConversation extends ChatEvent {
  final String otherUserId;
  OpenConversation(this.otherUserId);
}

class SendMessage extends ChatEvent {
  final String conversationId;
  final String text;
  SendMessage({required this.conversationId, required this.text});
}

class LoadMessages extends ChatEvent {
  final String conversationId;
  LoadMessages(this.conversationId);
}

class SubscribeToMessages extends ChatEvent {
  final String conversationId;
  SubscribeToMessages(this.conversationId);
}

class MessageReceived extends ChatEvent {
  final dynamic message;
  MessageReceived(this.message);
}

class MarkAsRead extends ChatEvent {
  final String conversationId;
  MarkAsRead(this.conversationId);
}

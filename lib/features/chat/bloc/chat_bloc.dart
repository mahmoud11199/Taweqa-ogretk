import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/config/supabase_config.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _repository;
  StreamSubscription? _messageSub;

  ChatBloc({required ChatRepository repository})
      : _repository = repository,
        super(const ChatState()) {
    on<LoadConversations>(_onLoadConversations);
    on<OpenConversation>(_onOpenConversation);
    on<SendMessage>(_onSendMessage);
    on<LoadMessages>(_onLoadMessages);
    on<SubscribeToMessages>(_onSubscribeToMessages);
    on<MessageReceived>(_onMessageReceived);
    on<MarkAsRead>(_onMarkAsRead);
  }

  Future<void> _onLoadConversations(
      LoadConversations event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) { emit(state.copyWith(isLoading: false)); return; }
      final conversations = await _repository.fetchConversations(user.id);
      emit(state.copyWith(isLoading: false, conversations: conversations));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onOpenConversation(
      OpenConversation event, Emitter<ChatState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final convId = await _repository.getOrCreateConversation(
        user.id, event.otherUserId,
      );
      emit(state.copyWith(activeConversationId: convId));
      add(LoadMessages(convId));
      add(SubscribeToMessages(convId));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event, Emitter<ChatState> emit) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;
    final optimisticMessage = ChatMessage(
      id: '',
      conversationId: event.conversationId,
      senderId: user.id,
      text: event.text,
      imageUrl: event.imageUrl,
      createdAt: DateTime.now(),
    );
    emit(state.copyWith(messages: [...state.messages, optimisticMessage]));
    try {
      await _repository.sendMessage(
        conversationId: event.conversationId,
        senderId: user.id,
        text: event.text,
        imageUrl: event.imageUrl,
      );
    } catch (e) {
      emit(state.copyWith(
        error: e.toString(),
        messages: state.messages
            .where((m) => !(m.id.isEmpty && m.senderId == user.id && m.text == event.text))
            .toList(),
      ));
    }
  }

  Future<void> _onLoadMessages(
      LoadMessages event, Emitter<ChatState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final messages = await _repository.fetchMessages(event.conversationId);
      emit(state.copyWith(isLoading: false, messages: messages));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> _onSubscribeToMessages(
      SubscribeToMessages event, Emitter<ChatState> emit) async {
    await _messageSub?.cancel();
    _messageSub = _repository
        .subscribeToMessages(event.conversationId)
        .listen((message) {
      if (!isClosed) add(MessageReceived(message));
    });
  }

  void _onMessageReceived(
      MessageReceived event, Emitter<ChatState> emit) {
    final message = event.message;
    final filtered = state.messages.where((m) =>
        m.id != '' || m.senderId != message.senderId || m.text != message.text,
    ).toList();
    emit(state.copyWith(messages: [...filtered, message]));
  }

  Future<void> _onMarkAsRead(
      MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      await _repository.markAsRead(event.conversationId, user.id);
    } catch (_) {}
  }

  @override
  Future<void> close() async {
    await _messageSub?.cancel();
    _repository.dispose();
    return super.close();
  }
}

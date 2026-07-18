import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadConversations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: const Text('الرسائل')),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.meterPrimary),
            );
          }
          if (state.conversations.isEmpty) {
            return const Center(
              child: Text('لا توجد محادثات', style: TextStyle(color: AppTheme.meterMuted)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conv = state.conversations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.meterPrimary.withAlpha(40),
                    child: Text(
                      (conv.otherUserName?.isNotEmpty == true ? conv.otherUserName! : '?')[0].toUpperCase(),
                      style: const TextStyle(color: AppTheme.meterPrimary, fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(conv.otherUserName ?? 'محادثة',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    conv.lastMessage ?? 'بدون رسائل',
                    style: const TextStyle(color: AppTheme.meterMuted, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: conv.lastMessageAt != null
                      ? Text(timeAgo(conv.lastMessageAt!),
                          style: const TextStyle(color: AppTheme.meterMuted, fontSize: 11))
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ChatScreen(conversationId: conv.id)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

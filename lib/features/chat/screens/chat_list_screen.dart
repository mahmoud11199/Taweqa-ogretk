import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('الرسائل', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
          }
          if (state.conversations.isEmpty) {
            return const Center(child: Text('لا توجد محادثات', style: TextStyle(color: Color(0xFF526480))));
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: state.conversations.length,
            itemBuilder: (context, index) {
              final conv = state.conversations[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1628),
                  border: Border.all(color: const Color(0xFF1C2B45)),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                  leading: CircleAvatar(
                    backgroundColor: const Color.fromRGBO(0, 229, 184, 0.12),
                    child: Text(
                      (conv.otherUserName?.isNotEmpty == true ? conv.otherUserName! : '?')[0].toUpperCase(),
                      style: const TextStyle(color: Color(0xFF00E5B8), fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(conv.otherUserName ?? 'محادثة', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFEDF2FC))),
                  subtitle: Text(
                    conv.lastMessage ?? 'بدون رسائل',
                    style: const TextStyle(color: Color(0xFF526480), fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  trailing: conv.lastMessageAt != null
                      ? Text(timeAgo(conv.lastMessageAt!), style: const TextStyle(color: Color(0xFF3A5070), fontSize: 11))
                      : null,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                      conversationId: conv.id, otherUserName: conv.otherUserName ?? '',
                    )));
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

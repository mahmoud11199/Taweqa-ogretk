import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/supabase_config.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;

  const ChatScreen({super.key, required this.conversationId, this.otherUserName = ''});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  int _lastMessageCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadMessages(widget.conversationId));
    context.read<ChatBloc>().add(SubscribeToMessages(widget.conversationId));
    context.read<ChatBloc>().add(MarkAsRead(widget.conversationId));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(
          _scrollController.position.maxScrollExtent,
        );
      }
    });
  }

  void _sendMessage({String? imageUrl}) {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    context.read<ChatBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      text: text,
      imageUrl: imageUrl,
    ));
    _messageController.clear();
  }

  Future<void> _pickImage() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file == null) return;
      final user = SupabaseConfig.client.auth.currentUser;
      if (user == null) return;
      final bytes = await File(file.path).readAsBytes();
      final ext = file.path.split('.').last;
      final fileName = 'chat/${widget.conversationId}/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await SupabaseConfig.client.storage.from('chat_images').uploadBinary(fileName, bytes);
      final imageUrl = SupabaseConfig.client.storage.from('chat_images').getPublicUrl(fileName);
      _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseConfig.client.auth.currentUser;
    final userId = currentUser?.id ?? '';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(title: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName : 'المحادثة')),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.meterPrimary),
                  );
                }
                if (state.messages.isEmpty) {
                  return const Center(
                    child: Text('لا توجد رسائل', style: TextStyle(color: AppTheme.meterMuted)),
                  );
                }
                if (state.messages.length > _lastMessageCount) {
                  _lastMessageCount = state.messages.length;
                  _scrollToBottom();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final isMe = userId.isNotEmpty && msg.senderId == userId;
                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? AppTheme.meterPrimary.withAlpha(40) : AppTheme.meterCard,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isMe ? const Radius.circular(4) : null,
                            bottomRight: !isMe ? const Radius.circular(4) : null,
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (msg.imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    msg.imageUrl!,
                                    width: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.meterMuted),
                                    loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(
                                      width: 200, height: 150,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                  ),
                                ),
                              ),
                            if (msg.text.isNotEmpty)
                              Text(
                                msg.text,
                                style: const TextStyle(color: Colors.white, fontSize: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.meterCard,
              border: Border(top: BorderSide(color: AppTheme.meterBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      filled: true,
                      fillColor: AppTheme.bgDeep,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.attach_file, color: AppTheme.meterMuted),
                ),
                IconButton(
                  onPressed: () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded, color: AppTheme.meterPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

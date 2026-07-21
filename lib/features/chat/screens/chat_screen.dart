import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
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
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage({String? imageUrl}) {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;
    context.read<ChatBloc>().add(SendMessage(
      conversationId: widget.conversationId, text: text, imageUrl: imageUrl,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل رفع الصورة: $e')));
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
      backgroundColor: const Color(0xFF080D18),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00E5B8)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.otherUserName.isNotEmpty ? widget.otherUserName : 'المحادثة', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEDF2FC))),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00E5B8)));
                }
                if (state.messages.isEmpty) {
                  return const Center(child: Text('لا توجد رسائل', style: TextStyle(color: Color(0xFF526480))));
                }
                if (state.messages.length > _lastMessageCount) {
                  _lastMessageCount = state.messages.length;
                  _scrollToBottom();
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  itemCount: state.messages.length,
                  itemBuilder: (context, index) {
                    final msg = state.messages[index];
                    final isMe = userId.isNotEmpty && msg.senderId == userId;
                    return Align(
                      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color.fromRGBO(0, 229, 184, 0.15) : const Color(0xFF0F1628),
                          border: isMe ? null : Border.all(color: const Color(0xFF1C2B45)),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomLeft: isMe ? const Radius.circular(4) : null,
                            bottomRight: !isMe ? const Radius.circular(4) : null,
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
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
                                    width: 200, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Color(0xFF526480)),
                                    loadingBuilder: (_, child, progress) => progress == null ? child : const SizedBox(
                                      width: 200, height: 150,
                                      child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5B8))),
                                    ),
                                  ),
                                ),
                              ),
                            if (msg.text.isNotEmpty)
                              Text(msg.text, style: const TextStyle(color: Color(0xFFEDF2FC), fontSize: 14)),
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
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F1628),
              border: Border(top: BorderSide(color: Color(0xFF1C2B45))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Color(0xFFEDF2FC)),
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالة...',
                      hintStyle: TextStyle(color: Color(0xFF526480)),
                      filled: true,
                      fillColor: Color(0xFF080D18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF1C2B45)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        borderSide: BorderSide(color: Color(0xFF1C2B45)),
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.attach_file, color: Color(0xFF526480)),
                ),
                IconButton(
                  onPressed: () => _sendMessage(),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF00E5B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

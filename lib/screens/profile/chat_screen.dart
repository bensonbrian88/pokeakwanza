import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/chat.dart';
import 'package:stynext/providers/chat_provider.dart';
import 'package:stynext/theme/app_theme.dart';
import 'package:stynext/providers/auth_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  Chat? _chat;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chat ??= ModalRoute.of(context)?.settings.arguments as Chat?;
    if (_chat != null) {
      ref.read(chatProvider).fetchMessages(_chat!.id);
    }
  }

  void _send() async {
    if (_chat == null || _controller.text.trim().isEmpty) return;
    final msg = _controller.text.trim();
    await ref.read(chatProvider).sendMessage(_chat!.id, msg);
    _controller.clear();
    // wait a moment then scroll
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(chatProvider);
    final messages =
        _chat != null ? provider.getMessagesFor(_chat!.id) : <Message>[];
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(_chat?.title ?? 'Chat'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: provider.isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final meId =
                          ref.read(authProvider).user?['id'] as int?;
                      final isMe = meId != null && m.senderId == meId;
                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppTheme.accentColor.withValues(alpha: 0.3)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(m.content),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

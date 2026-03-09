import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/providers/chat_provider.dart';
import 'package:stynext/theme/app_theme.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider).fetchChats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(chatProvider);
    final chats = provider.chats;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: provider.isLoadingChats
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? const Center(child: Text('No chats yet'))
              : ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final c = chats[index];
                    return ListTile(
                      title: Text(c.title),
                      subtitle: Text(c.lastMessage),
                      onTap: () {
                        Navigator.pushNamed(context, '/chat', arguments: c);
                      },
                    );
                  },
                ),
    );
  }
}

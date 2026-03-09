import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/chat.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class ChatProvider extends ChangeNotifier {
  List<Chat> _chats = [];
  final Map<int, List<Message>> _messages = {};
  bool _isLoadingChats = false;
  bool _isLoadingMessages = false;

  List<Chat> get chats => [..._chats];
  List<Message> getMessagesFor(int chatId) => [...?_messages[chatId]];
  bool get isLoadingChats => _isLoadingChats;
  bool get isLoadingMessages => _isLoadingMessages;

  void _setLoadingChats(bool val) {
    _isLoadingChats = val;
    notifyListeners();
  }

  void _setLoadingMessages(bool val) {
    _isLoadingMessages = val;
    notifyListeners();
  }

  Future<void> fetchChats() async {
    _setLoadingChats(true);
    try {
      final res = await ApiService.I.get(ApiConstants.chats);
      final data = res.data is Map ? res.data['data'] : res.data;
      if (data is List) {
        _chats = data.map((js) => Chat.fromJson(js)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching chats: $e');
    } finally {
      _setLoadingChats(false);
    }
  }

  Future<void> fetchMessages(int chatId) async {
    _setLoadingMessages(true);
    try {
      final path = '${ApiConstants.chats}/$chatId/messages';
      final res = await ApiService.I.get(path);
      final data = res.data is Map ? res.data['data'] : res.data;
      if (data is List) {
        _messages[chatId] = data.map((js) => Message.fromJson(js)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching messages for chat $chatId: $e');
    } finally {
      _setLoadingMessages(false);
    }
  }

  Future<Message?> sendMessage(int chatId, String message) async {
    try {
      final path = '${ApiConstants.chats}/$chatId/messages';
      final res = await ApiService.I.post(path, {'message': message});
      final json = res.data is Map ? (res.data['data'] ?? res.data) : res.data;
      if (json is Map<String, dynamic>) {
        final msg = Message.fromJson(json);
        _messages.putIfAbsent(chatId, () => []).add(msg);
        notifyListeners();
        return msg;
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
    return null;
  }
}

final chatProvider =
    ChangeNotifierProvider<ChatProvider>((ref) => ChatProvider());

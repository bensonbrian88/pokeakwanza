class Chat {
  final int id;
  final String title;
  final String lastMessage;
  final DateTime? updatedAt;

  Chat({
    required this.id,
    required this.title,
    required this.lastMessage,
    this.updatedAt,
  });

  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      lastMessage: json['last_message']?.toString() ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}

class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String content;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      chatId: json['chat_id'] is int
          ? json['chat_id']
          : int.tryParse('${json['chat_id']}') ?? 0,
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.tryParse('${json['sender_id']}') ?? 0,
      content: json['message']?.toString() ?? json['content']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

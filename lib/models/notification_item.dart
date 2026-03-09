class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] ??
        json['created_at'] ??
        DateTime.now().toIso8601String();
    return NotificationItem(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: DateTime.tryParse(ts.toString()) ?? DateTime.now(),
      isRead: json['is_read'] ?? false,
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stynext/models/notification_item.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final bool isLoading;
  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
  });
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? isLoading,
  }) =>
      NotificationState(
        notifications: notifications ?? this.notifications,
        isLoading: isLoading ?? this.isLoading,
      );
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final ApiService _api = ApiService.I;
  NotificationNotifier() : super(const NotificationState());

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _api.get(ApiConstants.notifications);
      final data = res.data is Map ? res.data['data'] : res.data;
      final list = (data as List)
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (_) {
      state = state.copyWith(notifications: [], isLoading: false);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _api.markNotificationsRead();
      final list = state.notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                body: n.body,
                timestamp: n.timestamp,
                isRead: true,
              ))
          .toList();
      state = state.copyWith(notifications: list);
    } catch (_) {}
  }

  void clearAll() {
    state = state.copyWith(notifications: []);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>(
        (ref) => NotificationNotifier());

import 'dart:developer' as developer;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/core/api/api_service.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();

  late FirebaseMessaging _messaging;
  // Local notifications plugin removed to maintain compatibility with
  // current Dart SDK. Foreground notifications are logged instead.

  factory FCMService() {
    return _instance;
  }

  FCMService._internal();

  /// Initialize FCM service - call this only once in main.dart
  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
      // Request notification permissions (iOS & Android 13+)
      await _requestNotificationPermission();

      // Local notifications plugin removed; no local channels created.

      // Listen to foreground messages
      _setupForegroundMessageListener();

      // Listen to message opened from notification tap
      _setupMessageOpenedAppListener();

      developer.log('✅ FCM Service initialized successfully');
    } catch (e) {
      developer.log('❌ FCM initialization error: $e', error: e);
    }
  }

  /// Request notification permissions from user
  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        developer.log('⚠️ User denied notification permission');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.authorized) {
        developer.log('✅ Notification permission granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        developer.log('✅ Notification permission provisional');
      }
    } catch (e) {
      developer.log('❌ Error requesting permission: $e', error: e);
    }
  }

  /// Setup local notifications plugin
  // Local notification setup removed; use server-side notifications or
  // re-add a compatible local notifications package when upgrading SDK.

  /// Listen to messages when app is in foreground
  void _setupForegroundMessageListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('💭 Foreground message received: ${message.messageId}');

      if (message.notification != null) {
        developer.log('🔔 Foreground notification: '
            '${message.notification!.title} - ${message.notification!.body}');
      }
    });
  }

  /// Listen to message when app is opened from notification
  void _setupMessageOpenedAppListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('🎯 Message opened from app: ${message.messageId}');
      _handleNotificationTap(message.data);
    });
  }

  /// Handle notification tap event
  void _handleNotificationTap(Map<String, dynamic> data) {
    try {
      developer.log('📌 Handling notification tap with data: $data');
      // Add custom logic here to navigate based on notification data
      // Example: if (data['type'] == 'order') { navigate to order screen }
    } catch (e) {
      developer.log('❌ Error handling notification tap: $e', error: e);
    }
  }

  /// Get FCM device token and register it with backend
  Future<void> registerFCMToken() async {
    try {
      // Get stored token to avoid duplicate submission
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('fcm_token_stored');

      // Get fresh token
      final token = await _messaging.getToken();

      if (token == null || token.isEmpty) {
        developer.log('⚠️ FCM token is null or empty, skipping registration');
        return;
      }

      // Avoid duplicate submissions
      if (storedToken == token) {
        developer.log('✅ FCM token already registered, skipping submission');
        return;
      }

      // Send token to backend
      await _submitTokenToBackend(token);

      // Cache the token locally
      await prefs.setString('fcm_token_stored', token);
      await prefs.setString('fcm_token', token);

      developer.log('✅ FCM token registered: ${token.substring(0, 20)}...');
    } catch (e) {
      developer.log('❌ Error registering FCM token: $e', error: e);
      // Don't rethrow - allow app to continue working without push notifications
    }
  }

  /// Submit FCM token to backend API
  Future<void> _submitTokenToBackend(String fcmToken) async {
    try {
      await ApiService.I.submitFCMToken(fcmToken);
      developer.log('✅ FCM token submitted to backend successfully');
    } catch (e) {
      developer.log('❌ Error submitting FCM token to backend: $e', error: e);
      // Don't rethrow - token submission is not critical
    }
  }

  /// Refresh FCM token (called when token refreshes)
  Future<void> refreshToken() async {
    try {
      final newToken = await _messaging.getToken();
      if (newToken != null && newToken.isNotEmpty) {
        await _submitTokenToBackend(newToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fcm_token', newToken);
        developer.log('✅ FCM token refreshed: ${newToken.substring(0, 20)}...');
      }
    } catch (e) {
      developer.log('❌ Error refreshing FCM token: $e', error: e);
    }
  }

  /// Get stored FCM token safely
  Future<String?> getStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('fcm_token');
    } catch (e) {
      developer.log('❌ Error retrieving stored FCM token: $e', error: e);
      return null;
    }
  }

  /// Unregister token (call on logout)
  Future<void> unregisterToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await getStoredToken();

      if (token != null && token.isNotEmpty) {
        // Notify backend of logout
        try {
          await ApiService.I.revokeFCMToken(token);
        } catch (e) {
          developer
              .log('⚠️ Error revoking token on backend (non-critical): $e');
        }
      }

      // Clear local token cache
      await prefs.remove('fcm_token');
      await prefs.remove('fcm_token_stored');

      developer.log('✅ FCM token unregistered');
    } catch (e) {
      developer.log('❌ Error unregistering FCM token: $e', error: e);
    }
  }
}

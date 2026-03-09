import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/api/api_constants.dart';

class FcmService {
  static bool _initialized = false;

  static Future<void> initAndRegister() async {
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
        _initialized = true;
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) return;
      final platform = kIsWeb
          ? 'web'
          : Platform.isAndroid
              ? 'android'
              : Platform.isIOS
                  ? 'ios'
                  : 'other';
      await ApiService.I.post(ApiConstants.saveDeviceToken, {
        'device_token': token,
        'platform': platform,
      });
    } catch (e) {
      debugPrint('FCM init error: $e');
    }
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stynext/core/api/api_service.dart';
import 'package:stynext/core/token_service.dart';
import 'package:stynext/config/app_config.dart';

class AppAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ApiService _api = ApiService.I;
  static final TokenService _tokens = TokenService();

  static Future<void> _markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_guest', false);
    final uid = _auth.currentUser?.uid;
    if (uid != null) await prefs.setString('firebase_uid', uid);
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('firebase_uid');
      // Do not remove backend auth_token here; backend logout should manage it
    }
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      if (EnvironmentConfig.disableGoogleSignIn) {
        throw Exception('Google sign-in disabled');
      }
      final googleUser = await GoogleSignIn(
        serverClientId:
            "1010349768288-oscv31harpp2ps52d01ov255tsv3197n.apps.googleusercontent.com",
      ).signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCred = await _auth.signInWithCredential(credential);
      await _markLoggedIn();
      return userCred;
    } catch (e) {
      print("Google Sign-In Error: $e");
      rethrow;
    }
  }

  static Future<UserCredential?> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return null;
    final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(result.accessToken!.token);
    final userCred = await FirebaseAuth.instance
        .signInWithCredential(facebookAuthCredential);
    await _markLoggedIn();
    return userCred;
  }

  static Future<Map<String, dynamic>> loginWithGoogleAndSync() async {
    final userCred = await signInWithGoogle();
    if (userCred == null) {
      throw Exception('Google sign-in cancelled');
    }
    final data = await syncUserToBackend();
    return data;
  }

  static Future<void> verifyPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String message) onError,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on some devices
        try {
          await _auth.signInWithCredential(credential);
          await _markLoggedIn();
        } catch (e) {
          onError('Auto verification failed');
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  static Future<UserCredential> signInWithOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final userCred = await _auth.signInWithCredential(credential);
    await _markLoggedIn();
    return userCred;
  }

  static Future<Map<String, dynamic>> syncUserToBackend() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No Firebase user found after OTP verification');
    }
    final data = await ApiService.I.firebaseLogin(
      firebaseUid: user.uid,
      phone: user.phoneNumber,
    );
    final token =
        data['token'] ?? data['access_token'] ?? data['data']?['token'];
    final userData = data['user'] ?? data['data']?['user'];
    if (token is String && token.isNotEmpty) {
      await _tokens.saveToken(token);
      if (userData is Map<String, dynamic>) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
      }
      _api.setBearerToken(token);
    }
    return data;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) return true;
    return _auth.currentUser != null;
  }
}

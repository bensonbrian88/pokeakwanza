import 'dart:async';
import 'package:stynext/core/error_handler.dart';

class SubmissionGuard {
  static final Map<String, Completer<bool>> _pendingRequests = {};
  static const Duration _timeout = Duration(seconds: 30);

  /// Prevents duplicate submissions for the same request
  /// Returns true if the request was allowed, false if a duplicate was blocked
  static Future<bool> executeOnce<T>(
    String key,
    Future<T> Function() request,
  ) async {
    // If request already in flight, return the same future
    if (_pendingRequests.containsKey(key)) {
      try {
        await _pendingRequests[key]!
            .future
            .timeout(_timeout, onTimeout: () => false);
        return true;
      } catch (e) {
        ErrorHandler.logError('SubmissionGuard', e);
        return false;
      }
    }

    final completer = Completer<bool>();
    _pendingRequests[key] = completer;

    try {
      await request();
      completer.complete(true);
      return true;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  static void clearAll() {
    _pendingRequests.clear();
  }

  static void clear(String key) {
    _pendingRequests.remove(key);
  }

  static bool isPending(String key) => _pendingRequests.containsKey(key);
}
